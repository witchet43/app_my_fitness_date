import React,{useCallback,useEffect,useState} from 'react';
import {Pressable,StyleSheet,Text,TextInput,View} from 'react-native';
import type {Session} from '@supabase/supabase-js';
import {supabase} from '../lib/supabase';

type Incident={
 report_id:string;target_type:string;reason:string;report_status:string;
 reported_at:string;priority:'urgent'|'high'|'normal';
 attention_deadline:string;overdue:boolean;
 escalation_status:'not_escalated'|'open'|'closed';
 target_preview:string|null;
};
type Decision={id:string;mode:'escalate'|'review'};
const OPTIONS=['urgent','high','normal'] as const;
export default function AdminIncidents({session}:{session:Session}){
 const [items,setItems]=useState<Incident[]>([]);
 const [selected,setSelected]=useState<Decision|null>(null);
 const [priority,setPriority]=useState<Incident['priority']>('urgent');
 const [note,setNote]=useState('');
 const [busy,setBusy]=useState(false);
 const [message,setMessage]=useState('');
 const refresh=useCallback(async()=>{
   if(!supabase)return;
   const {data,error}=await supabase.rpc('moderator_incident_queue',{p_limit:30});
   if(error)throw error;
   setItems((data||[]) as Incident[]);
 },[session.user.id]);
 useEffect(()=>{
   let active=true;
   void refresh().catch(e=>{if(active)setMessage(errorText(e));});
   return ()=>{active=false;};
 },[refresh]);
 async function apply(){
   if(!supabase||!selected)return;
   if(note.trim().length<10||note.trim().length>300){
     setMessage('La justificación debe contener entre 10 y 300 caracteres.');
     return;
   }
   setBusy(true);setMessage('');
   try{
     const result=selected.mode==='escalate'
       ? await supabase.rpc('moderator_escalate_report',{
           p_report_id:selected.id,p_priority:priority,p_note:note.trim(),
         })
       : await supabase.rpc('moderator_review_escalation',{
           p_report_id:selected.id,p_note:note.trim(),
         });
     if(result.error)throw result.error;
     setSelected(null);setNote('');
     await refresh();
     setMessage(selected.mode==='escalate'
       ? 'Incidente escalado. Requiere revisión de otro moderador.'
       : 'Revisión independiente registrada y auditada.');
   }catch(e){setMessage(errorText(e));}
   finally{setBusy(false);}
 }
 return <View testID="admin-incidents">
   <Text style={s.title}>Atención de incidentes</Text>
   <Text style={s.help}>Cola priorizada de denuncias. Los plazos indican urgencia de revisión,
    no garantizan atención automática. No se revela quién denunció.</Text>
   <Pressable testID="incidents-refresh" accessibilityRole="button"
     style={s.refresh} disabled={busy}
     onPress={()=>void refresh().catch(e=>setMessage(errorText(e)))}>
     <Text style={s.link}>Actualizar cola</Text>
   </Pressable>
   {message?<Text style={s.message}>{message}</Text>:null}
   {items.length===0?<Text style={s.help}>No hay incidentes abiertos.</Text>:null}
   {items.map(item=><View key={item.report_id} style={s.card}>
     <Text style={s.emphasis}>{item.priority.toUpperCase()} · {item.reason} · {item.report_status}</Text>
     <Text style={s.body}>{item.target_type}: {item.target_preview||'Sin descripción disponible'}</Text>
     <Text style={s.help}>Denuncia: {new Date(item.reported_at).toLocaleString('es-MX')}</Text>
     <Text style={[s.help,item.overdue&&s.warning]}>
       {item.overdue?'REQUIERE ATENCIÓN':'Objetivo de revisión'}:
       {' '}{new Date(item.attention_deadline).toLocaleString('es-MX')}
     </Text>
     <Text style={s.help}>Escalamiento: {item.escalation_status}</Text>
     {item.escalation_status==='not_escalated'&&<Pressable
       testID={'incident-escalate-'+item.report_id} style={s.action}
       accessibilityRole="button" disabled={busy}
       onPress={()=>{setSelected({id:item.report_id,mode:'escalate'});setPriority(item.priority);setNote('');}}>
       <Text style={s.link}>Escalar a segunda revisión</Text>
     </Pressable>}
     {item.escalation_status==='open'&&<Pressable
       testID={'incident-review-'+item.report_id} style={s.action}
       accessibilityRole="button" disabled={busy}
       onPress={()=>{setSelected({id:item.report_id,mode:'review'});setNote('');}}>
       <Text style={s.link}>Registrar revisión independiente</Text>
     </Pressable>}
     {selected?.id===item.report_id&&<View style={s.confirm}>
       <Text style={s.body}>{selected.mode==='escalate'?'Escalar incidente':'Revisión por otro moderador'}</Text>
       {selected.mode==='escalate'&&<View style={s.row}>
         {OPTIONS.map(value=><Pressable key={value}
           accessibilityRole="radio" accessibilityState={{checked:priority===value}}
           style={[s.option,priority===value&&s.active]}
           onPress={()=>setPriority(value)}><Text style={s.body}>{value}</Text></Pressable>)}
       </View>}
       <TextInput multiline style={s.input} maxLength={300} value={note}
         accessibilityLabel="Justificación del escalamiento"
         onChangeText={setNote} placeholder="Justificación de 10 a 300 caracteres"
         placeholderTextColor="#8CA1A8"/>
       <View style={s.row}>
         <Pressable style={s.option} disabled={busy} onPress={()=>{setSelected(null);setNote('');}}>
           <Text style={s.body}>Cancelar</Text>
         </Pressable>
         <Pressable testID="incident-confirm" style={s.primary} disabled={busy}
           accessibilityRole="button" onPress={()=>void apply()}>
           <Text style={s.primaryText}>{busy?'Guardando…':'Confirmar'}</Text>
         </Pressable>
       </View>
     </View>}
   </View>)}
   <Text style={s.help}>Un incidente escalado solo puede cerrarse tras revisión por un
    moderador distinto, y luego resolver la denuncia. Ninguna escalación
    suspende automáticamente una cuenta ni sustituye atención humana.</Text>
 </View>;
}
function errorText(e:unknown){return e instanceof Error?e.message:'No fue posible revisar el incidente';}
const s=StyleSheet.create({
 title:{color:'#F4FAFA',fontSize:19,fontWeight:'900',marginTop:18,marginBottom:6},
 help:{color:'#A8BEC4',fontSize:12,lineHeight:19,marginVertical:5},
 body:{color:'#E0E9EB',fontSize:13,lineHeight:20},
 emphasis:{color:'#B6F266',fontSize:12,fontWeight:'900',marginBottom:8},
 warning:{color:'#FFD28B',fontWeight:'800'},
 card:{backgroundColor:'#172A32',borderColor:'#344B56',borderWidth:1,padding:14,borderRadius:12,marginVertical:7},
 refresh:{alignSelf:'flex-end',padding:10,minHeight:44},
 link:{color:'#B6F266',fontSize:12,fontWeight:'800'},
 message:{color:'#FFE3BD',fontSize:12,marginVertical:8},
 action:{padding:10,minHeight:44,justifyContent:'center'},
 confirm:{padding:10,backgroundColor:'#263A42',borderRadius:9,marginTop:8},
 row:{flexDirection:'row',gap:8,flexWrap:'wrap',marginTop:8,alignItems:'center'},
 option:{padding:10,borderColor:'#4A646E',borderWidth:1,borderRadius:8,minHeight:44},
 active:{borderColor:'#B6F266'},
 input:{minHeight:68,textAlignVertical:'top',borderColor:'#617983',borderWidth:1,color:'#FFFFFF',padding:10,borderRadius:8,marginTop:8},
 primary:{padding:12,backgroundColor:'#B6F266',borderRadius:9,minHeight:44,justifyContent:'center'},
 primaryText:{color:'#152516',fontWeight:'900'},
});
