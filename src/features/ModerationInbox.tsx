import React,{useCallback,useEffect,useState} from 'react';
import {Pressable,StyleSheet,Text,TextInput,View} from 'react-native';
import type {Session} from '@supabase/supabase-js';
import {supabase} from '../lib/supabase';

type Notification={id:string;kind:string;message:string;created_at:string;read_at:string|null};
type AppealCase={report_id:string;post_id:string;appeal_status:string|null;hidden_at:string};
export default function ModerationInbox({session}:{session:Session}){
 const [notices,setNotices]=useState<Notification[]>([]);
 const [cases,setCases]=useState<AppealCase[]>([]);
 const [selected,setSelected]=useState<string|null>(null);
 const [statement,setStatement]=useState('');
 const [busy,setBusy]=useState(false);
 const [message,setMessage]=useState('');

 const refresh=useCallback(async()=>{
  if(!supabase)return;
  const [a,b]=await Promise.all([
   supabase.rpc('my_notifications',{p_limit:30}),
   supabase.rpc('my_appealable_posts'),
  ]);
  if(a.error)throw a.error;
  if(b.error)throw b.error;
  setNotices((a.data||[]) as Notification[]);
  setCases((b.data||[]) as AppealCase[]);
 },[session.user.id]);

 useEffect(()=>{
  let active=true;
  void refresh().catch(e=>{if(active)setMessage(formatError(e));});
  return ()=>{active=false;};
 },[refresh]);

 async function markRead(id:string){
  if(!supabase)return;
  setBusy(true);setMessage('');
  try{
   const {error}=await supabase.rpc('mark_notification_read',{p_notification_id:id});
   if(error)throw error;
   await refresh();
  }catch(e){setMessage(formatError(e));}finally{setBusy(false);}
 }
 async function submit(reportId:string){
  if(!supabase)return;
  if(statement.trim().length<20||statement.trim().length>500){
   setMessage('La apelación debe contener entre 20 y 500 caracteres.');
   return;
  }
  setBusy(true);setMessage('');
  try{
   const {error}=await supabase.rpc('submit_moderation_appeal',{
    p_report_id:reportId,p_statement:statement.trim(),
   });
   if(error)throw error;
   setSelected(null);setStatement('');
   await refresh();
   setMessage('Apelación registrada para revisión independiente.');
  }catch(e){setMessage(formatError(e));}finally{setBusy(false);}
 }
 return <View>
  <Text style={s.title}>Buzón de seguridad</Text>
  <Text style={s.help}>Solo tú puedes consultar estas notificaciones y apelaciones. No se muestra la identidad de quien denunció.</Text>
  <Pressable style={s.refresh} disabled={busy}
   onPress={()=>void refresh().catch(e=>setMessage(formatError(e)))}>
    <Text style={s.link}>Actualizar</Text>
  </Pressable>
  {message?<Text style={s.message}>{message}</Text>:null}
  <Text style={s.subtitle}>Notificaciones</Text>
  {notices.length===0?<Text style={s.help}>No tienes notificaciones de moderación.</Text>:null}
  {notices.map(n=><View key={n.id} style={s.card}>
   <Text style={s.category}>{n.read_at?'LEÍDA':'NUEVA'} · {n.kind}</Text>
   <Text style={s.body}>{n.message}</Text>
   <Text style={s.help}>{new Date(n.created_at).toLocaleString('es-MX')}</Text>
   {!n.read_at&&<Pressable disabled={busy} onPress={()=>void markRead(n.id)}>
    <Text style={s.link}>Marcar como leída</Text>
   </Pressable>}
  </View>)}
  <Text style={s.subtitle}>Apelaciones sobre publicaciones</Text>
  {cases.length===0?<Text style={s.help}>No tienes publicaciones ocultas que puedas apelar.</Text>:null}
  {cases.map(c=><View key={c.post_id} style={s.card}>
    <Text style={s.category}>PUBLICACIÓN OCULTA</Text>
    <Text style={s.help}>Ocultada: {new Date(c.hidden_at).toLocaleString('es-MX')}</Text>
    {c.appeal_status?<Text style={s.body}>Estado de apelación: {c.appeal_status}</Text>:
      <Pressable disabled={busy} onPress={()=>{setSelected(c.report_id);setStatement('');}}>
        <Text style={s.link}>Presentar una apelación</Text>
      </Pressable>}
    {selected===c.report_id&&<View style={s.box}>
      <Text style={s.body}>Explica por qué solicitas una revisión independiente.</Text>
      <TextInput multiline maxLength={500} style={s.input}
       placeholder="Motivo de la apelación" placeholderTextColor="#90A4AD"
       value={statement} onChangeText={setStatement}/>
      <Text style={s.help}>{statement.length}/500 caracteres</Text>
      <Pressable style={s.primary} disabled={busy} onPress={()=>void submit(c.report_id)}>
        <Text style={s.primaryText}>{busy?'Enviando…':'Enviar apelación'}</Text>
      </Pressable>
      <Pressable style={s.cancel} onPress={()=>{setSelected(null);setStatement('');}}>
        <Text style={s.link}>Cancelar</Text>
      </Pressable>
    </View>}
  </View>)}
  <Text style={s.help}>Las notificaciones son internas; no se envían correos ni mensajes push. Las apelaciones no suspenden automáticamente las medidas de moderación.</Text>
 </View>;
}
function formatError(e:unknown){return e instanceof Error?e.message:'No se pudo completar la operación';}
const s=StyleSheet.create({
 title:{color:'#F3FAF9',fontWeight:'900',fontSize:22,marginBottom:7},
 subtitle:{color:'#F3FAF9',fontWeight:'800',fontSize:18,marginTop:18,marginBottom:8},
 help:{color:'#A8BBC1',fontSize:12,lineHeight:18,marginVertical:5},
 category:{color:'#B6F266',fontSize:10,fontWeight:'900',marginBottom:6},
 body:{color:'#E0E9EB',fontSize:13,lineHeight:20},
 card:{padding:14,borderRadius:13,backgroundColor:'#182B34',marginVertical:6,borderWidth:1,borderColor:'#344C56'},
 refresh:{alignSelf:'flex-end',padding:9},
 link:{color:'#B6F266',fontSize:12,fontWeight:'800',marginVertical:6},
 message:{color:'#FFE1B5',fontSize:12,marginVertical:8},
 box:{marginTop:10,padding:10,backgroundColor:'#283C43',borderRadius:9},
 input:{color:'#FFFFFF',padding:10,borderColor:'#59757E',borderWidth:1,borderRadius:8,minHeight:80,textAlignVertical:'top',marginTop:8},
 primary:{backgroundColor:'#B6F266',padding:12,borderRadius:8,alignItems:'center'},
 primaryText:{color:'#14220F',fontWeight:'900'},
 cancel:{alignSelf:'center',padding:8},
});
