import React, { useCallback, useEffect, useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import type { Session } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';
import ReportPicker,{type ReportReason} from './ReportPicker';

type SportsEvent = { id:string; title:string; description:string;
  sport:string; city:string; starts_at:string };
type RSVP = { event_id:string };

export default function LiveTogether({ session }:{session:Session}) {
  const [events,setEvents]=useState<SportsEvent[]>([]);
  const [joined,setJoined]=useState<string[]>([]);
  const [busy,setBusy]=useState(false);
  const [message,setMessage]=useState('');
  const [reportId,setReportId]=useState<string|null>(null);

  const refresh=useCallback(async ()=>{
    if(!supabase)return;
    const [eventResult,rsvpResult]=await Promise.all([
      supabase.from('sport_events').select('id,title,description,sport,city,starts_at')
        .gte('starts_at',new Date().toISOString()).order('starts_at',{ascending:true}).limit(30),
      supabase.from('event_rsvps').select('event_id').eq('user_id',session.user.id),
    ]);
    if(eventResult.error)throw eventResult.error;
    if(rsvpResult.error)throw rsvpResult.error;
    setEvents((eventResult.data||[]) as SportsEvent[]);
    setJoined(((rsvpResult.data||[]) as RSVP[]).map(item=>item.event_id));
  },[session.user.id]);

  useEffect(()=>{
    void refresh().catch(e=>setMessage(formatError(e)));
  },[refresh]);

  async function changeAttendance(eventId:string,isJoined:boolean){
    if(!supabase)return;
    setBusy(true);setMessage('');
    try{
      const response=isJoined
        ? await supabase.from('event_rsvps').delete()
            .eq('event_id',eventId).eq('user_id',session.user.id)
        : await supabase.from('event_rsvps').insert({event_id:eventId,user_id:session.user.id});
      if(response.error)throw response.error;
      await refresh();
      setMessage(isJoined?'Participación cancelada.':'Tu participación quedó registrada.');
    }catch(e){setMessage(formatError(e));}finally{setBusy(false);}
  }

  async function submitReport(eventId:string,reason:ReportReason){
    if(!supabase)return;
    setBusy(true);setMessage('');
    try{
      const {error}=await supabase.rpc('submit_safety_report',{
        p_target_type:'event',p_target_id:eventId,p_reason:reason,p_details:null,
      });
      if(error)throw error;
      setReportId(null);setMessage('Actividad reportada para revisión.');
    }catch(e){setMessage(formatError(e));}finally{setBusy(false);}
  }
  return <View testID="activities-view">
    <Text style={s.title}>Fitness Together</Text>
    <Text style={s.hint}>Actividades deportivas públicas para personas con intereses afines.
      No hace falta activar FitDating.</Text>
    <Pressable style={s.refresh} onPress={()=>void refresh().catch(e=>setMessage(formatError(e)))}>
      <Text style={s.refreshText}>Actualizar actividades</Text>
    </Pressable>
    {message?<Text style={s.warning}>{message}</Text>:null}
    {events.length===0 && <Text style={s.hint}>Todavía no hay actividades organizadas y aprobadas en el entorno de desarrollo.</Text>}
    {events.map(event=>{
      const attending=joined.includes(event.id);
      return <View key={event.id} style={s.card}>
        <Text style={s.sport}>{event.sport.toUpperCase()}</Text>
        <Text style={s.heading}>{event.title}</Text>
        <Text style={s.body}>{event.description}</Text>
        <Text style={s.hint}>{event.city} · {new Date(event.starts_at).toLocaleString('es-MX')}</Text>
        <Pressable testID={'activity-rsvp-'+event.id} accessibilityRole="button"
          accessibilityLabel={attending?'Cancelar participación':'Confirmar participación'}
          style={attending?s.outline:s.primary} disabled={busy}
          onPress={()=>void changeAttendance(event.id,attending)}>
          <Text style={attending?s.outlineText:s.primaryText}>
            {attending?'Cancelar participación':'Me interesa asistir'}
          </Text>
        </Pressable>
        <Pressable disabled={busy} onPress={()=>setReportId(event.id)} style={s.reportButton}>
          <Text style={s.reportText}>Reportar actividad</Text>
        </Pressable>
        {reportId===event.id && <ReportPicker busy={busy} onSubmit={reason=>void submitReport(event.id,reason)}
          onCancel={()=>setReportId(null)}/>}
      </View>;
    })}
    <Text style={s.hint}>Para esta versión únicamente organizadores aprobados por administración pueden crear eventos.
      Las listas de asistentes no son públicas.</Text>
  </View>;
}
function formatError(error:unknown){return error instanceof Error?error.message:'No fue posible cargar las actividades';}
const s=StyleSheet.create({
 title:{fontSize:23,fontWeight:'900',color:'#F7FAFA',marginBottom:7},
 hint:{color:'#A3B6BF',fontSize:12,lineHeight:19,marginVertical:7},
 card:{backgroundColor:'#16262D',borderColor:'#28414B',borderWidth:1,padding:16,borderRadius:14,marginVertical:8},
 sport:{color:'#B6F266',fontSize:11,fontWeight:'800',marginBottom:7},
 heading:{color:'#F7FAFA',fontSize:18,fontWeight:'800',marginBottom:5},
 body:{color:'#CEDCE1',fontSize:13,lineHeight:19},
 primary:{backgroundColor:'#B6F266',padding:12,borderRadius:10,alignItems:'center',marginTop:10},
 primaryText:{color:'#142014',fontWeight:'900'},
 outline:{borderColor:'#B6F266',borderWidth:1,padding:12,borderRadius:10,alignItems:'center',marginTop:10},
 outlineText:{color:'#B6F266',fontWeight:'800'},
 warning:{color:'#F3D2A1',fontSize:12,marginVertical:8},
 refresh:{padding:10,alignSelf:'flex-start'},
 refreshText:{color:'#B6F266',fontSize:12,fontWeight:'800'},
 reportButton:{padding:11,alignSelf:'flex-start'},
 reportText:{color:'#FFC5C0',fontSize:12},
});
