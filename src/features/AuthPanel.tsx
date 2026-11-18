import React, { useState } from 'react';
import { Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import { supabase } from '../lib/supabase';
import { isAdult } from '../domain/onboarding';

/** App-wide sign-in. Dating remains a separate, strictly opt-in experience. */
export default function AuthPanel() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [dob, setDob] = useState('');
  const [adultConfirmed, setAdultConfirmed] = useState(false);
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState('');

  async function submit(signUp: boolean) {
    if (!supabase) return;
    if (signUp && (!adultConfirmed || !isAdult(dob))) {
      setMessage('Solo adultos: confirma los 18 años e introduce una fecha válida.');
      return;
    }
    if (!email.trim() || password.length < 6) {
      setMessage('Introduce un correo y una contraseña de al menos seis caracteres.');
      return;
    }
    setBusy(true);
    setMessage('');
    try {
      const { data, error } = signUp
        ? await supabase.auth.signUp({ email: email.trim(), password })
        : await supabase.auth.signInWithPassword({ email: email.trim(), password });
      if (error) throw error;
      if (signUp && !data.session) {
        setMessage('Revisa tu correo y confirma el registro para iniciar sesión.');
      }
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'No fue posible iniciar sesión.');
    } finally {
      setBusy(false);
      setPassword('');
    }
  }

  return (
    <View style={styles.box}>
      <Text style={styles.title}>Tu cuenta fitness</Text>
      <Text style={styles.help}>Con una cuenta puedes participar en Comunidad y Actividades. No necesitas activar citas.</Text>
      <TextInput style={styles.input} placeholder="Correo electrónico" placeholderTextColor="#92A3AA"
        autoCapitalize="none" autoComplete="email" keyboardType="email-address"
        value={email} onChangeText={setEmail} />
      <TextInput style={styles.input} placeholder="Contraseña" placeholderTextColor="#92A3AA"
        secureTextEntry value={password} onChangeText={setPassword} />
      <Text style={styles.help}>Para crear cuenta de prueba: fecha de nacimiento (AAAA-MM-DD)</Text>
      <TextInput style={styles.input} placeholder="1994-01-15" placeholderTextColor="#92A3AA"
        keyboardType="numbers-and-punctuation" value={dob} onChangeText={setDob} />
      <Pressable onPress={() => setAdultConfirmed(value => !value)} style={styles.check}>
        <Text style={styles.help}>{adultConfirmed ? '☑' : '☐'} Confirmo que tengo 18 años o más.</Text>
      </Pressable>
      <Pressable disabled={busy} onPress={() => void submit(false)} style={styles.primary}>
        <Text style={styles.primaryText}>{busy ? 'Procesando...' : 'Entrar'}</Text>
      </Pressable>
      <Pressable disabled={busy} onPress={() => void submit(true)} style={styles.secondary}>
        <Text style={styles.help}>Crear cuenta de desarrollo</Text>
      </Pressable>
      {message ? <Text style={styles.message}>{message}</Text> : null}
      <Text style={styles.warning}>Entorno de desarrollo: edad autodeclarada, sin verificación de identidad ni moderación completa. No usar con personas reales.</Text>
    </View>
  );
}
const styles = StyleSheet.create({
  box:{backgroundColor:'#16262D',padding:18,borderRadius:16},
  title:{fontSize:20,fontWeight:'800',color:'#F6FAFA',marginBottom:10},
  help:{color:'#B8CACF',fontSize:13,lineHeight:20,marginVertical:5},
  input:{borderColor:'#435860',borderWidth:1,padding:12,marginVertical:6,
    borderRadius:10,color:'#F6FAFA',backgroundColor:'#0C1920'},
  check:{paddingVertical:6},
  primary:{backgroundColor:'#B6F266',padding:14,borderRadius:12,alignItems:'center',marginTop:10},
  primaryText:{fontWeight:'900',color:'#142014'},
  secondary:{alignItems:'center',padding:10},
  message:{color:'#FFE3A8',fontSize:13,marginTop:8},
  warning:{color:'#8EA4AD',fontSize:11,lineHeight:17,marginTop:8},
});
