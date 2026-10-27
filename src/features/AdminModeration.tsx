import React,{useCallback,useEffect,useState} from 'react';
import {Pressable,StyleSheet,Text,TextInput,View} from 'react-native';
import type {Session} from '@supabase/supabase-js';
import {supabase} from '../lib/supabase';
import AdminAppeals from './AdminAppeals';
import AdminIncidents from './AdminIncidents';

type Status='pending'|'reviewing'|'resolved'|'dismissed'|'all';
type Action='review'|'dismiss'|'resolve'|'hide_post'|'restore_post';
type Report={
 report_id:string;target_type:'user'|'post'|'event';target_id:string;
 reason:string;details:string|null;status:string;created_at:string;target_preview:string|null;
};
type Audit={report_id:string;action:string;previous_status:string;resulting_status:string;
 note:string;occurred_at:string};
const STATUSES:Status[]=['pending','reviewing','resolved','dismissed','all'];
const ACTIONS:Array<{action:Action;label:string}>= [
 {action:'review',label:'En revisión'},
 {action:'dismiss',label:'Descartar'},
 {action:'resolve',label:'Resolver'},
 {action:'hide_post',label:'Ocultar publicación'},
 {action:'restore_post',label:'Restaurar publicación'},
];
const MAX_NOTE_LENGTH=200;

export default function AdminModeration({session}:{session:Session}){
 const [reports,setReports]=useState<Report[]>([]);
 const [recent,setRecent]=useState<Audit[]>([]);
 const [status,setStatus]=useState<Status>('pending');
 const [note,setNote]=useState('');
 const [pending,setPending]=useState<{id:string;action:Action}|null>(null);
 const [busy,setBusy]=useState(false);
 const [message,setMessage]=useState('');

 const refresh=useCallback(async()=>{
   if(!supabase)return;
   const client=supabase;
   const [reportResult,auditResult]=await Promise.all([
     client.rpc('moderator_list_reports',{p_status:status,p_limit:30}),
     client.rpc('moderator_recent_actions',{p_limit:10}),
   ]);
   if(reportResult.error)throw reportResult.error;
   if(auditResult.error)throw auditResult.error;
   setReports((reportResult.data||[]) as Report[]);
   setRecent((auditResult.data||[]) as Audit[]);
 },[status,session.user.id]);

 useEffect(()=>{
   let active=true;
   void refresh().catch(error=>{
     if(active)setMessage(errorText(error));
   });
   return ()=>{active=false;};
 },[refresh]);

 function select(id:string,action:Action){
   setPending({id,action});
   setMessage('');
 }
 async function decide(){
   if(!supabase || !pending)return;
   if(note.trim().length<5 || note.trim().length>MAX_NOTE_LENGTH){
     setMessage('Escribe una justificación entre 5 y 200 caracteres.');
     return;
   }
   setBusy(true);setMessage('');
   try{
     const {error}=await supabase.rpc('moderator_decide',{
       p_report_id:pending.id,p_action:pending.action,p_note:note.trim(),
     });
     if(error)throw error;
     setPending(null);
     setNote('');
     await refresh();
     setMessage('Decisión guardada en el historial de auditoría.');
   }catch(error){setMessage(errorText(error));}
   finally{setBusy(false);}
 }

 return <View>
  <Text style={s.title}>Centro de moderación</Text>
  <Text style={s.hint}>Área restringida. El servidor valida los permisos para cada consulta y decisión. No compartir capturas de denuncias ni datos de usuarios.</Text>
  <Text style={s.subhead}>Filtrar denuncias</Text>
  <View style={s.filterRow}>
   {STATUSES.map(value=><Pressable key={value}
     style={[s.filter,status===value&&s.selected]} onPress={()=>{
       setStatus(value);setPending(null);setMessage('');
     }}>
     <Text style={[s.filterText,status===value&&s.selectedText]}>{value}</Text>
   </Pressable>)}
  </View>
  <Pressable style={s.refresh} disabled={busy}
   onPress={()=>void refresh().catch(error=>setMessage(errorText(error)))}>
   <Text style={s.link}>Actualizar</Text>
  </Pressable>
  {message?<Text style={s.message}>{message}</Text>:null}
  {reports.length===0?<Text style={s.hint}>No hay denuncias en este filtro.</Text>:null}
  {reports.map(report=><View key={report.report_id} style={s.card}>
   <Text style={s.eyebrow}>{report.target_type.toUpperCase()} · {report.reason} · {report.status}</Text>
   <Text style={s.cardTitle}>{report.target_preview||'Elemento no disponible'}</Text>
   <Text style={s.hint}>{new Date(report.created_at).toLocaleString('es-MX')}</Text>
   {report.details?<Text style={s.body}>{report.details}</Text>:null}
   <View style={s.actions}>
    {ACTIONS.filter(item=>report.target_type==='post'||!['hide_post','restore_post'].includes(item.action)).map(item=>
     <Pressable key={item.action} style={s.action} disabled={busy}
      onPress={()=>select(report.report_id,item.action)}>
      <Text style={s.actionText}>{item.label}</Text>
     </Pressable>)}
   </View>
   {pending?.id===report.report_id&&<View style={s.confirm}>
    <Text style={s.body}>Confirmar acción: <Text style={s.strong}>{pending.action}</Text></Text>
    <TextInput multiline style={s.input} maxLength={MAX_NOTE_LENGTH}
      placeholder="Justificación obligatoria" placeholderTextColor="#8B9EA5"
      value={note} onChangeText={setNote}/>
    <Text style={s.hint}>{note.length}/200 caracteres</Text>
    <View style={s.confirmButtons}>
     <Pressable style={s.cancel} disabled={busy} onPress={()=>{setPending(null);setNote('');}}>
      <Text style={s.body}>Cancelar</Text>
     </Pressable>
     <Pressable style={s.primary} disabled={busy} onPress={()=>void decide()}>
      <Text style={s.primaryText}>{busy?'Guardando…':'Confirmar decisión'}</Text>
     </Pressable>
    </View>
   </View>}
  </View>)}
  <AdminIncidents session={session}/>
  <AdminAppeals session={session}/>
  <Text style={s.subhead}>Últimas acciones</Text>
  {recent.length===0?<Text style={s.hint}>Aún no hay decisiones registradas.</Text>:null}
  {recent.map((item,index)=><View key={item.report_id+':'+index} style={s.audit}>
    <Text style={s.body}>{item.action}: {item.previous_status} → {item.resulting_status}</Text>
    <Text style={s.hint}>{item.note} · {new Date(item.occurred_at).toLocaleString('es-MX')}</Text>
  </View>)}
  <Text style={s.hint}>La plataforma requiere procedimientos de revisión, apelaciones, retención y atención humana antes de una beta real. Resolver una denuncia no implica suspender una cuenta.</Text>
 </View>;
}
function errorText(error:unknown){return error instanceof Error?error.message:'Error administrativo';}
const s=StyleSheet.create({
 title:{color:'#F4F9F9',fontWeight:'900',fontSize:22,marginBottom:8},
 subhead:{color:'#F4F9F9',fontWeight:'800',fontSize:18,marginTop:18,marginBottom:9},
 hint:{color:'#A6B9C0',fontSize:11,lineHeight:18,marginVertical:4},
 body:{color:'#D7E2E5',fontSize:13,lineHeight:19},
 strong:{color:'#B6F266',fontWeight:'900'},
 eyebrow:{color:'#B6F266',fontSize:11,fontWeight:'900',marginBottom:6},
 cardTitle:{color:'#FFFFFF',fontSize:16,fontWeight:'800',marginBottom:6},
 card:{padding:14,backgroundColor:'#172932',borderRadius:13,borderWidth:1,borderColor:'#314651',marginBottom:12},
 filterRow:{flexDirection:'row',flexWrap:'wrap',gap:6},
 filter:{paddingHorizontal:9,paddingVertical:7,borderRadius:8,borderWidth:1,borderColor:'#41545C'},
 selected:{backgroundColor:'#B6F266',borderColor:'#B6F266'},
 filterText:{color:'#D5E1E4',fontSize:11},
 selectedText:{color:'#172016',fontWeight:'800'},
 refresh:{padding:10,alignSelf:'flex-end'},
 link:{color:'#B6F266',fontWeight:'800'},
 actions:{flexDirection:'row',flexWrap:'wrap',gap:7,marginTop:9},
 action:{padding:9,borderRadius:8,borderWidth:1,borderColor:'#5F7B86'},
 actionText:{color:'#DFEAEC',fontSize:11},
 confirm:{backgroundColor:'#253A40',padding:12,borderRadius:9,marginTop:11},
 input:{marginTop:8,color:'#FFFFFF',borderWidth:1,borderColor:'#62757E',padding:10,
  borderRadius:8,minHeight:60,textAlignVertical:'top'},
 confirmButtons:{flexDirection:'row',gap:10,alignItems:'center',justifyContent:'flex-end'},
 cancel:{padding:11},
 primary:{backgroundColor:'#B6F266',borderRadius:9,padding:12},
 primaryText:{color:'#182514',fontWeight:'900',fontSize:12},
 message:{color:'#F8D7AB',fontSize:12,marginVertical:10},
 audit:{borderBottomWidth:1,borderBottomColor:'#2A424B',paddingVertical:10},
});
