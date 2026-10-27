import React, { useCallback, useEffect, useState } from 'react';
import { Pressable, Share, StyleSheet, Text, TextInput, View } from 'react-native';
import type { Session } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';

type AccountStatus = { pending: boolean; requested_at: string | null; earliest_review_at: string | null };
type AccountCenterProps = { session: Session; onStatusChange: (pending: boolean) => void };

export default function AccountCenter({session,onStatusChange}:AccountCenterProps) {
 const [status,setStatus]=useState<AccountStatus|null>(null);
 const [password,setPassword]=useState('');
 const [confirmation,setConfirmation]=useState('');
 const [busy,setBusy]=useState(false);
 const [message,setMessage]=useState('');

 const refresh=useCallback(async()=>{
  if(!supabase)return;
  const {data,error}=await supabase.rpc('my_account_status');
  if(error)throw error;
  const result=data as AccountStatus;
  setStatus(result);onStatusChange(Boolean(result?.pending));
 // onStatusChange updates parent state but does not affect the RPC inputs.
 },[session.user.id]);
 useEffect(()=>{
  let active=true;
  async function load(){
   try{if(active)await refresh();}
   catch(e){if(active)setMessage(formatError(e));}
  }
  void load();return ()=>{active=false;};
 },[refresh]);

 async function exportOwnData(){
  if(!supabase)return;
  setBusy(true);setMessage('');
  try{
   const {data,error}=await supabase.rpc('my_account_export');
   if(error)throw error;
   if(!data)throw new Error('No se pudieron recuperar los datos.');
   // The user chooses the OS share target. Never log or upload this file.
   await Share.share({
     title:'my_fitness_date — exportación de datos propia',
     message:JSON.stringify(data,null,2),
   });
   setMessage('Exportación preparada. Revisa dónde compartiste o guardaste los datos.');
  }catch(e){setMessage(formatError(e));}finally{setBusy(false);}
 }
 async function requestDeletion(){
  if(!supabase)return;
  if(confirmation.trim()!=='SOLICITAR'){
   setMessage('Escribe SOLICITAR exactamente para confirmar.');
   return;
  }
  if(!session.user.email||!password){
   setMessage('Vuelve a introducir tu contraseña de esta cuenta.');
   return;
  }
  setBusy(true);setMessage('');
  try{
   // Client-side recent password check: server still enforces auth.uid().
   // Do not represent this as a strong server-enforced reauthentication proof.
   const result=await supabase.auth.signInWithPassword({
     email:session.user.email,password,
   });
   if(result.error)throw result.error;
   if(result.data.user?.id!==session.user.id){
     await supabase.auth.signOut();
     throw new Error('La cuenta autenticada cambió. Vuelve a iniciar sesión.');
   }
   const {error}=await supabase.rpc('request_account_deletion');
   if(error)throw error;
   await refresh();
   setPassword('');setConfirmation('');
   setMessage('Solicitud registrada. Tu perfil queda oculto mientras se revisa; tu cuenta aún NO se ha eliminado.');
  }catch(e){setMessage(formatError(e));}finally{setBusy(false);}
 }
 async function cancelRequest(){
  if(!supabase)return;
  setBusy(true);setMessage('');
  try{
   const {error}=await supabase.rpc('cancel_account_deletion');
   if(error)throw error;
   await refresh();
   setMessage('Solicitud cancelada. Las citas permanecen desactivadas hasta que vuelvas a aceptarlas.');
  }catch(e){setMessage(formatError(e));}finally{setBusy(false);}
 }
 return <View>
  <Text style={styles.title}>Privacidad y cuenta</Text>
  <Text style={styles.help}>Tus datos deportivos y románticos son independientes. Puedes exportar una copia técnica de tus datos o solicitar la baja.</Text>
  <View style={styles.card}>
   <Text style={styles.subtitle}>Exportación de datos</Text>
   <Text style={styles.help}>Incluye perfil social, configuración privada de Dating, horarios, publicaciones, eventos, participaciones y notificaciones. No incluye copias de seguridad, logs ni todo el historial de Supabase Auth.</Text>
   <Pressable disabled={busy} style={styles.secondary} onPress={()=>void exportOwnData()}>
    <Text style={styles.link}>Exportar mis datos</Text>
   </Pressable>
   <Text style={styles.warning}>La exportación incluye información personal sensible. Solo compártela o guárdala en un destino seguro.</Text>
  </View>
  <View style={styles.card}>
   <Text style={styles.subtitle}>Solicitud de baja</Text>
   {status?.pending ? <>
    <Text style={styles.warning}>Solicitud pendiente desde {status.requested_at?new Date(status.requested_at).toLocaleString('es-MX'):'fecha desconocida'}.</Text>
    <Text style={styles.help}>El perfil y publicaciones quedan ocultos a terceros mientras se tramita. La eliminación definitiva requiere revisión administrativa; no se ha borrado todavía tu usuario de Supabase Auth.</Text>
    <Pressable style={styles.secondary} disabled={busy} onPress={()=>void cancelRequest()}>
     <Text style={styles.link}>Cancelar solicitud de baja</Text>
    </Pressable>
   </> : <>
    <Text style={styles.help}>La solicitud oculta tu perfil social, impide nuevas publicaciones y desactiva las citas. No elimina inmediatamente tu cuenta ni borra los datos: el proceso definitivo todavía es administrativo.</Text>
    <Text style={styles.help}>Confirma con tu contraseña y escribe SOLICITAR.</Text>
    <TextInput style={styles.input} secureTextEntry placeholder="Contraseña actual"
      placeholderTextColor="#8FA5AD" value={password} onChangeText={setPassword}/>
    <TextInput style={styles.input} autoCapitalize="characters" placeholder="Escribe SOLICITAR"
      placeholderTextColor="#8FA5AD" value={confirmation} onChangeText={setConfirmation}/>
    <Pressable style={styles.danger} disabled={busy} onPress={()=>void requestDeletion()}>
     <Text style={styles.dangerText}>{busy?'Procesando…':'Solicitar eliminación de mi cuenta'}</Text>
    </Pressable>
   </>}
  </View>
  {message?<Text style={styles.feedback}>{message}</Text>:null}
  <Text style={styles.help}>Solo entorno de desarrollo. Las solicitudes no se ejecutan automáticamente después de siete días. Los plazos definitivos de conservación están pendientes de definición legal.</Text>
 </View>;
}
function formatError(error:unknown){return error instanceof Error?error.message:'Operación no disponible';}
const styles=StyleSheet.create({
 title:{fontSize:23,fontWeight:'900',color:'#F6FAFA',marginBottom:7},
 subtitle:{color:'#F5FAFA',fontWeight:'800',fontSize:18,marginBottom:8},
 card:{backgroundColor:'#172A32',padding:16,borderRadius:13,marginVertical:9,borderColor:'#2F4651',borderWidth:1},
 help:{color:'#AFBFC5',fontSize:12,lineHeight:19,marginVertical:6},
 warning:{color:'#FFD3A9',fontSize:12,lineHeight:19,marginTop:6},
 secondary:{padding:12,borderWidth:1,borderColor:'#B6F266',borderRadius:10,alignItems:'center',marginTop:10},
 link:{color:'#B6F266',fontWeight:'800',fontSize:13},
 input:{backgroundColor:'#0F1C23',padding:12,borderColor:'#4C626B',borderWidth:1,
  borderRadius:10,color:'#FFFFFF',marginVertical:6},
 danger:{backgroundColor:'#A34B49',padding:14,borderRadius:10,alignItems:'center',marginTop:10},
 dangerText:{color:'#FFFFFF',fontWeight:'900'},
 feedback:{color:'#FFE2BD',fontSize:12,marginVertical:9},
});
