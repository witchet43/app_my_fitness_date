import React,{useCallback,useEffect,useState} from 'react';
import {Pressable,StyleSheet,Text,TextInput,View} from 'react-native';
import type {Session} from '@supabase/supabase-js';
import {supabase} from '../lib/supabase';
type Appeal={appeal_id:string;post_id:string;statement:string;status:string;created_at:string;post_preview:string|null};
type Decision='upheld'|'overturned';
export default function AdminAppeals({session}:{session:Session}){
 const [appeals,setAppeals]=useState<Appeal[]>([]);
 const [showAll,setShowAll]=useState(false);
 const [selected,setSelected]=useState<{id:string;decision:Decision}|null>(null);
 const [note,setNote]=useState('');
 const [busy,setBusy]=useState(false);
 const [message,setMessage]=useState('');
 const refresh=useCallback(async()=>{
  if(!supabase)return;
  const {data,error}=await supabase.rpc('moderator_list_appeals',{
   p_status:showAll?'all':'pending',p_limit:30,
  });
  if(error)throw error;
  setAppeals((data||[]) as Appeal[]);
 },[session.user.id,showAll]);
 useEffect(()=>{
  let active=true;
  void refresh().catch(e=>{if(active)setMessage(errorText(e));});
  return ()=>{active=false;};
 },[refresh]);
 async function decide(){
  if(!supabase || !selected)return;
  if(note.trim().length<10||note.trim().length>300){
   setMessage('Escribe una justificación de 10 a 300 caracteres.');
   return;
  }
  setBusy(true);setMessage('');
  try{
   const {error}=await supabase.rpc('moderator_decide_appeal',{
    p_appeal_id:selected.id,p_decision:selected.decision,p_note:note.trim(),
   });
   if(error)throw error;
   setSelected(null);setNote('');
   await refresh();
   setMessage('Resolución auditada y notificación privada enviada.');
  }catch(e){setMessage(errorText(e));}
  finally{setBusy(false);}
 }
 return <View>
  <Text style={s.title}>Apelaciones</Text>
  <Text style={s.help}>Una apelación debe resolverla un moderador distinto de quien ocultó originalmente la publicación.</Text>
  <Pressable style={s.filter} onPress={()=>setShowAll(x=>!x)}>
   <Text style={s.link}>{showAll?'Mostrar pendientes':'Ver todas'}</Text>
  </Pressable>
  {message?<Text style={s.message}>{message}</Text>:null}
  {appeals.length===0?<Text style={s.help}>No hay apelaciones en este filtro.</Text>:null}
  {appeals.map(item=><View key={item.appeal_id} style={s.card}>
   <Text style={s.eyebrow}>{item.status.toUpperCase()}</Text>
   <Text style={s.body}>Publicación: {item.post_preview||'Contenido no disponible'}</Text>
   <Text style={s.body}>Apelación: {item.statement}</Text>
   <Text style={s.help}>{new Date(item.created_at).toLocaleString('es-MX')}</Text>
   {item.status==='pending'&&<View style={s.actions}>
     <Pressable disabled={busy} onPress={()=>setSelected({id:item.appeal_id,decision:'upheld'})}>
      <Text style={s.link}>Mantener decisión</Text>
     </Pressable>
     <Pressable disabled={busy} onPress={()=>setSelected({id:item.appeal_id,decision:'overturned'})}>
      <Text style={s.link}>Aceptar apelación</Text>
     </Pressable>
   </View>}
   {selected?.id===item.appeal_id&&<View style={s.confirm}>
     <Text style={s.body}>Confirmar: {selected.decision}</Text>
     <TextInput multiline maxLength={300} style={s.input} value={note}
       onChangeText={setNote} placeholder="Justificación obligatoria"
       placeholderTextColor="#8CA1A8"/>
     <Pressable style={s.primary} disabled={busy} onPress={()=>void decide()}>
       <Text style={s.primaryText}>{busy?'Guardando…':'Confirmar resolución'}</Text>
     </Pressable>
     <Pressable onPress={()=>{setSelected(null);setNote('');}}><Text style={s.link}>Cancelar</Text></Pressable>
   </View>}
  </View>)}
 </View>;
}
function errorText(e:unknown){return e instanceof Error?e.message:'Error al procesar la apelación';}
const s=StyleSheet.create({
 title:{color:'#F4FAFA',fontSize:19,fontWeight:'900',marginTop:18,marginBottom:6},
 help:{color:'#A8BEC4',fontSize:12,lineHeight:19,marginVertical:5},
 card:{backgroundColor:'#172A32',borderColor:'#34515A',borderWidth:1,padding:14,borderRadius:12,marginVertical:7},
 eyebrow:{color:'#B6F266',fontWeight:'900',fontSize:11,marginBottom:8},
 body:{color:'#DAE6EA',fontSize:13,lineHeight:19,marginVertical:4},
 actions:{flexDirection:'row',gap:18,flexWrap:'wrap',marginTop:8},
 filter:{alignSelf:'flex-end',padding:8},
 link:{color:'#B6F266',fontWeight:'800',fontSize:12,marginVertical:8},
 confirm:{padding:12,backgroundColor:'#2A3F47',borderRadius:8,marginTop:9},
 input:{minHeight:65,textAlignVertical:'top',borderColor:'#68808A',borderWidth:1,color:'#FFFFFF',padding:10,borderRadius:8,marginVertical:8},
 primary:{padding:11,backgroundColor:'#B6F266',borderRadius:9,alignItems:'center'},
 primaryText:{color:'#1A2B16',fontWeight:'900'},
 message:{color:'#FFE3BD',fontSize:12},
});
