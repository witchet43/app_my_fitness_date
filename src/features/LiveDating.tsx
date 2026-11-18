import React, { useCallback, useEffect, useRef, useState } from 'react';
import {
  Pressable, ScrollView, StyleSheet, Text, TextInput, View,
} from 'react-native';
import type { Session } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';
import { isAdult } from '../domain/onboarding';
import { parseScheduleDrafts, type ScheduleDraft } from '../domain/scheduleDraft';
import type { GymShieldMode } from '../domain/gymShield';
import ReportPicker,{type ReportReason} from './ReportPicker';

type Gym = { id: string; name: string; city: string };
type Candidate = { user_id: string; display_name: string; city: string; sports: string[] };
type OwnSettings = {
  display_name: string; city: string; sports: string[];
  gym_id: string; mode: GymShieldMode; dating_enabled: boolean;
  weekly_slots: Array<{ day: number; startMinutes: number; endMinutes: number }>;
};
const DAYS = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
const MODE_OPTIONS: Array<{ value: GymShieldMode; label: string }> = [
  { value: 'other_gyms', label: 'Solo personas de otros gimnasios' },
  { value: 'same_gym_other_time', label: 'Mi gimnasio, pero en otros horarios' },
];

export default function LiveDating({ session }: { session: Session }) {
  const [message, setMessage] = useState('');
  const [busy, setBusy] = useState(false);
  const [gyms, setGyms] = useState<Gym[]>([]);
  const [gymId, setGymId] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [city, setCity] = useState('Querétaro');
  const [sports, setSports] = useState('Running, Pesas');
  const [dob, setDob] = useState('');
  const [mode, setMode] = useState<GymShieldMode>('other_gyms');
  const [slots, setSlots] = useState<ScheduleDraft[]>([
    { id: 1, day: 1, start: '07:00', end: '08:30' },
  ]);
  const nextSlotId = useRef(2);
  const [hasSetup, setHasSetup] = useState(false);
  const [enabled, setEnabled] = useState(false);
  const [candidates, setCandidates] = useState<Candidate[]>([]);
  const [reportId,setReportId]=useState<string|null>(null);


  const refreshCandidates = useCallback(async () => {
    if (!supabase) return;
    const { data, error } = await supabase.rpc('discover_dating_candidates', { p_limit: 20 });
    if (error) throw error;
    setCandidates((data || []) as Candidate[]);
  }, []);

  useEffect(() => {
    if (!session || !supabase) {
      // Never carry private onboarding fields between signed-in users on one device.
      setCandidates([]);
      setReportId(null);
      setEnabled(false);
      setHasSetup(false);
      setGyms([]);
      setGymId('');
      setDisplayName('');
      setCity('Querétaro');
      setSports('Running, Pesas');
      setDob('');
      setMode('other_gyms');
      setSlots([{ id: 1, day: 1, start: '07:00', end: '08:30' }]);
      nextSlotId.current = 2;
      return;
    }
    const client = supabase;
    let cancelled = false;
    async function load() {
      setBusy(true);
      try {
        const [gymResult, ownResult] = await Promise.all([
          client.from('gyms').select('id,name,city').order('name'),
          client.rpc('my_dating_setup'),
        ]);
        if (gymResult.error) throw gymResult.error;
        if (ownResult.error) throw ownResult.error;
        const birthResult = await client.rpc('my_dating_birthdate');
        if (birthResult.error) throw birthResult.error;
        if (cancelled) return;
        const catalog = (gymResult.data || []) as Gym[];
        setGyms(catalog);
        const current = ((ownResult.data || []) as OwnSettings[])[0];
        setHasSetup(Boolean(current));
        if (current) {
          if (typeof birthResult.data === 'string') setDob(birthResult.data);
          setDisplayName(current.display_name);
          setCity(current.city);
          setSports(current.sports.join(', '));
          setGymId(current.gym_id);
          setMode(current.mode);
          setEnabled(current.dating_enabled);
          const saved = current.weekly_slots.map((s, index) => ({
            id: index + 1, day: s.day, start: clockString(s.startMinutes), end: clockString(s.endMinutes),
          }));
          setSlots(saved);
          nextSlotId.current = saved.length + 1;
        } else {
          setGymId(catalog[0]?.id ?? '');
        }
        const result = await client.rpc('discover_dating_candidates', { p_limit: 20 });
        if (result.error) throw result.error;
        if (!cancelled) setCandidates((result.data || []) as Candidate[]);
      } catch (e) {
        if (!cancelled) setMessage(errorMessage(e));
      } finally {
        if (!cancelled) setBusy(false);
      }
    }
    void load();
    return () => { cancelled = true; };
  }, [session?.user.id]);


  async function saveSettings() {
    if (!supabase) return;
    if (!isAdult(dob)) {
      setMessage('Ingresa una fecha válida. FitDating solo está disponible para mayores de 18 años.');
      return;
    }
    const parsed = parseScheduleDrafts(slots, mode === 'same_gym_other_time');
    if (!parsed.ok) {
      setMessage(parsed.error);
      return;
    }
    if (!gymId || !displayName.trim()) {
      setMessage('Completa tu nombre visible y selecciona un gimnasio.');
      return;
    }
    setBusy(true);
    setMessage('');
    try {
      const { error } = await supabase.rpc('save_dating_setup', {
        p_display_name: displayName.trim(),
        p_city: city.trim(),
        p_sports: sports.split(',').map(s => s.trim()).filter(Boolean),
        p_dob: dob,
        p_gym_id: gymId,
        p_mode: mode,
        p_weekly_slots: parsed.slots,
        p_dating_enabled: true,
      });
      if (error) throw error;
      setEnabled(true);
      setHasSetup(true);
      await refreshCandidates();
      setMessage('Preferencias guardadas. Gym Shield ya se evalúa en el servidor.');
    } catch (e) {
      setMessage(errorMessage(e));
    } finally { setBusy(false); }
  }

  async function turnOffDating() {
    if (!supabase) return;
    setBusy(true);
    try {
      const { error } = await supabase.rpc('disable_dating');
      if (error) throw error;
      setEnabled(false);
      setCandidates([]);
      setMessage('FitDating desactivado. La cuenta social permanece activa.');
    } catch (e) {
      setMessage(errorMessage(e));
    } finally { setBusy(false); }
  }

  async function blockCandidate(userId: string) {
    if (!supabase) return;
    setBusy(true);
    try {
      const { error } = await supabase.rpc('block_user', { p_blocked_user_id: userId });
      if (error) throw error;
      await refreshCandidates();
      setMessage('Cuenta bloqueada para el descubrimiento romántico.');
    } catch (e) {
      setMessage(errorMessage(e));
    } finally { setBusy(false); }
  }


  async function submitReport(userId:string,reason:ReportReason){
    if(!supabase)return;
    setBusy(true);setMessage('');
    try{
      const {error}=await supabase.rpc('submit_safety_report',{
        p_target_type:'user',p_target_id:userId,p_reason:reason,p_details:null,
      });
      if(error)throw error;
      setReportId(null);setMessage('Reporte recibido para revisión.');
    }catch(e){setMessage(errorMessage(e));}finally{setBusy(false);}
  }
  return (
    <ScrollView nestedScrollEnabled>
      <Text style={styles.heading}>Gym Shield · Perfil privado</Text>
      <Text style={styles.hint}>Datos del gimnasio y los horarios privados. Los demás usuarios solo reciben perfiles permitidos, sin conocer por qué alguien fue excluido.</Text>
      <Text style={styles.caption}>Nombre público</Text>
      <TextInput testID="dating-name" accessibilityLabel="Nombre para citas"
        style={styles.field} placeholder="Tu nombre visible" placeholderTextColor="#80949B" value={displayName} onChangeText={setDisplayName} />
      <Text style={styles.caption}>Ciudad</Text>
      <TextInput style={styles.field} value={city} onChangeText={setCity} />
      <Text style={styles.caption}>Deportes (separados por coma)</Text>
      <TextInput style={styles.field} value={sports} onChangeText={setSports} />
      <Text style={styles.caption}>Fecha de nacimiento · privada, autodeclarada</Text>
      <TextInput testID="dating-dob" accessibilityLabel="Fecha de nacimiento para citas"
        style={styles.field} placeholder="1995-08-30" placeholderTextColor="#80949B" value={dob} onChangeText={setDob} keyboardType="numbers-and-punctuation" />
      <Text style={styles.caption}>Gimnasio habitual · solo visible para ti</Text>
      {gyms.length === 0 ? <Text style={styles.feedback}>No hay gimnasios configurados. Aplica la migración SQL al proyecto Supabase.</Text> : null}
      {gyms.map(g => (
        <Pressable key={g.id} style={[styles.choice, gymId === g.id && styles.active]}
          onPress={() => setGymId(g.id)}>
          <Text style={styles.body}>{gymId === g.id ? '◉' : '○'} {g.name} · {g.city}</Text>
        </Pressable>
      ))}
      <Text style={styles.caption}>¿Con quién te gustaría coincidir?</Text>
      {MODE_OPTIONS.map(option => (
        <Pressable key={option.value} testID={'dating-mode-'+option.value}
          accessibilityRole="radio" accessibilityLabel={option.label}
          accessibilityState={{checked:mode===option.value}}
          style={[styles.choice, mode === option.value && styles.active]}
          onPress={() => setMode(option.value)}>
          <Text style={styles.body}>{mode === option.value ? '◉' : '○'} {option.label}</Text>
        </Pressable>
      ))}
      <Text style={styles.caption}>Horarios semanales privados · máximo 14 bloques</Text>
      <Text style={styles.hint}>Cada día puede tener horarios distintos. Gym Shield compara todos los bloques.</Text>
      {slots.map(slot => (
        <View key={slot.id} style={styles.slotCard}>
          <View style={styles.slotRow}>
            <Pressable style={styles.dayControl} onPress={() => setSlots(existing => existing.map(s =>
              s.id === slot.id ? { ...s, day: (s.day + 6) % 7 } : s))}>
              <Text style={styles.body}>◀</Text>
            </Pressable>
            <Text style={[styles.body, styles.slotDay]}>{DAYS[slot.day]}</Text>
            <Pressable style={styles.dayControl} onPress={() => setSlots(existing => existing.map(s =>
              s.id === slot.id ? { ...s, day: (s.day + 1) % 7 } : s))}>
              <Text style={styles.body}>▶</Text>
            </Pressable>
            <Pressable style={styles.removeControl} onPress={() => setSlots(existing => existing.filter(s => s.id !== slot.id))}>
              <Text style={styles.removeText}>Eliminar</Text>
            </Pressable>
          </View>
          <View style={styles.hours}>
            <TextInput style={[styles.field, styles.hour]} value={slot.start}
              onChangeText={startTime => setSlots(existing => existing.map(s =>
                s.id === slot.id ? { ...s, start: startTime } : s))}
              placeholder="07:00" keyboardType="numbers-and-punctuation"
              placeholderTextColor="#80949B" />
            <Text style={styles.body}>a</Text>
            <TextInput style={[styles.field, styles.hour]} value={slot.end}
              onChangeText={endTime => setSlots(existing => existing.map(s =>
                s.id === slot.id ? { ...s, end: endTime } : s))}
              placeholder="08:30" keyboardType="numbers-and-punctuation"
              placeholderTextColor="#80949B" />
          </View>
        </View>
      ))}
      <Pressable style={styles.choice} disabled={slots.length >= 14}
        onPress={() => { const id = nextSlotId.current++;
          setSlots(current => [...current, { id, day: 1, start: '07:00', end: '08:30' }]);
        }}>
        <Text style={styles.body}>＋ Agregar bloque semanal ({slots.length}/14)</Text>
      </Pressable>
      <Pressable testID="dating-save" accessibilityRole="button" accessibilityLabel="Guardar preferencias de citas"
        style={styles.button} disabled={busy || gyms.length === 0} onPress={() => void saveSettings()}>
        <Text style={styles.buttonText}>{busy ? 'Guardando...' : hasSetup && enabled ? 'Guardar preferencias' : 'Guardar y activar FitDating'}</Text>
      </Pressable>
      {enabled ? (
        <Pressable style={styles.secondaryButton} disabled={busy} onPress={() => void turnOffDating()}>
          <Text style={styles.body}>Desactivar citas (mantener cuenta social)</Text>
        </Pressable>
      ) : null}
      {message ? <Text style={styles.feedback}>{message}</Text> : null}
      <Text style={styles.heading}>Personas recomendadas</Text>
      {!enabled ? <Text style={styles.hint}>Activa voluntariamente FitDating para recibir recomendaciones.</Text> : null}
      {enabled && candidates.length === 0 ? <Text style={styles.hint}>Todavía no hay perfiles compatibles.</Text> : null}
      {enabled && candidates.map(c => (
        <View key={c.user_id} style={styles.candidate}>
          <View style={{ flex: 1 }}>
            <Text style={styles.name}>{c.display_name}</Text>
            <Text style={styles.body}>{c.city} · {c.sports.join(' · ')}</Text>
          </View>
          <View style={styles.actions}>
            <Pressable disabled={busy} onPress={() => void blockCandidate(c.user_id)} style={styles.block}>
              <Text style={styles.blockText}>Bloquear</Text>
            </Pressable>
            <Pressable disabled={busy} onPress={()=>setReportId(c.user_id)} style={styles.block}>
              <Text style={styles.blockText}>Reportar</Text>
            </Pressable>
          </View>
        </View>
      ))}
      {reportId && <ReportPicker busy={busy} onSubmit={reason=>void submitReport(reportId,reason)}
        onCancel={()=>setReportId(null)}/>} 
      <Text style={styles.hint}>Aviso: la autodeclaración de edad no constituye verificación. No habilitar una beta con usuarios reales sin los controles adicionales de seguridad y moderación.</Text>
    </ScrollView>
  );
}
function clockString(total: number): string {
  return String(Math.floor(total / 60)).padStart(2, '0') + ':' + String(total % 60).padStart(2, '0');
}
function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
const styles = StyleSheet.create({
  heading: { color: '#FFFFFF', fontWeight: '800', fontSize: 20, marginTop: 15, marginBottom: 10 },
  hint: { color: '#9DB0B8', lineHeight: 19, marginBottom: 14, fontSize: 12 },
  caption: { color: '#B6F266', fontSize: 12, fontWeight: '700', marginTop: 12, marginBottom: 5 },
  field: { color: '#FFFFFF', backgroundColor: '#172931', borderWidth: 1, borderColor: '#3C545E', paddingHorizontal: 12, paddingVertical: 11, borderRadius: 10, marginBottom: 7 },
  choice: { borderColor: '#324952', borderWidth: 1, padding: 12, borderRadius: 11, marginVertical: 4 },
  active: { borderColor: '#B6F266', backgroundColor: '#29402C' },
  body: { color: '#DFEAED', fontSize: 13 },
  feedback: { color: '#FFE6A6', marginVertical: 12, fontSize: 12 },
  button: { backgroundColor: '#B6F266', padding: 14, alignItems: 'center', borderRadius: 12, marginTop: 16 },
  buttonText: { color: '#14211D', fontWeight: '800' },
  secondaryButton: { padding: 12, alignItems: 'center', marginVertical: 5 },
  slotCard: { padding: 11, borderRadius: 10, borderWidth: 1, borderColor: '#344C55', marginVertical: 4 },
  slotRow: { flexDirection: 'row', alignItems: 'center', marginBottom: 8 },
  slotDay: { minWidth: 42, textAlign: 'center', fontWeight: '800' },
  dayControl: { padding: 10 },
  removeControl: { marginLeft: 'auto', padding: 9 },
  removeText: { color: '#FFD6D6', fontSize: 12 },
  hours: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-around' },
  hour: { width: '42%' },
  candidate: { backgroundColor: '#182930', borderRadius: 12, padding: 13, flexDirection: 'row', alignItems: 'center', marginVertical: 5 },
  name: { color: '#FFFFFF', fontWeight: '800', fontSize: 16 },
  block: { borderColor: '#80676B', borderWidth: 1, borderRadius: 8, padding: 8 },
  actions: {gap:6},
  blockText: { color: '#FFD6D6', fontSize: 11 },
});
