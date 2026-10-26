import React, { useMemo, useState } from 'react';
import { Pressable, SafeAreaView, ScrollView, StatusBar, StyleSheet, Text, View } from 'react-native';
import { currentUser, demoActivities, demoCandidates, demoPosts } from './src/demo/fixtures';
import { isEligibleForDating, type GymShieldMode } from './src/domain/gymShield';

type Tab = 'community' | 'together' | 'dating';
const TABS: Array<{ id: Tab; title: string; emoji: string }> = [
  { id: 'community', title: 'Comunidad', emoji: '◉' },
  { id: 'together', title: 'Actividades', emoji: '◎' },
  { id: 'dating', title: 'Citas', emoji: '♡' },
];

export default function App() {
  const [tab, setTab] = useState<Tab>('community');
  const [mode, setMode] = useState<GymShieldMode>('other_gyms');

  const matches = useMemo(
    () => demoCandidates.filter((candidate) =>
      isEligibleForDating({ ...currentUser, mode }, candidate)),
    [mode],
  );

  return (
    <SafeAreaView style={styles.safe}>
      <StatusBar barStyle="light-content" />
      <View style={styles.header}>
        <Text style={styles.kicker}>TRAIN · CONNECT · BELONG</Text>
        <Text style={styles.brand}>my_fitness_<Text style={styles.accent}>date</Text></Text>
        <Text style={styles.subtitle}>Tu comunidad fitness, a tu ritmo.</Text>
      </View>

      <View style={styles.tabs}>
        {TABS.map((item) => (
          <Pressable
            key={item.id}
            onPress={() => setTab(item.id)}
            accessibilityRole="tab"
            accessibilityState={{ selected: tab === item.id }}
            style={[styles.tab, tab === item.id && styles.tabActive]}
          >
            <Text style={[styles.tabText, tab === item.id && styles.tabTextActive]}>
              {item.emoji} {item.title}
            </Text>
          </Pressable>
        ))}
      </View>

      <ScrollView contentContainerStyle={styles.content}>
        <View style={styles.notice}>
          <Text style={styles.noticeText}>DEMO LOCAL · Datos ficticios · Sin usuarios reales</Text>
        </View>

        {tab === 'community' && (
          <>
            <Text style={styles.sectionTitle}>Tu gente se mueve</Text>
            <Text style={styles.lead}>Una red social para compartir lo que te apasiona del deporte.</Text>
            {demoPosts.map((post) => (
              <View key={post.author} style={styles.card}>
                <Text style={styles.tag}>{post.sport}</Text>
                <Text style={styles.cardTitle}>{post.author}</Text>
                <Text style={styles.body}>{post.body}</Text>
              </View>
            ))}
          </>
        )}

        {tab === 'together' && (
          <>
            <Text style={styles.sectionTitle}>Entrena acompañado</Text>
            <Text style={styles.lead}>Actividades grupales que podrás descubrir y organizar.</Text>
            {demoActivities.map((activity) => (
              <View key={activity.title} style={styles.card}>
                <Text style={styles.tag}>{activity.sport}</Text>
                <Text style={styles.cardTitle}>{activity.title}</Text>
                <Text style={styles.body}>{activity.detail}</Text>
              </View>
            ))}
          </>
        )}

        {tab === 'dating' && (
          <>
            <Text style={styles.sectionTitle}>Fitness Dating</Text>
            <Text style={styles.lead}>Las citas son opcionales. Tú decides qué parte de tu círculo quieres mantener separada.</Text>
            <View style={styles.card}>
              <Text style={styles.cardTitle}>Gym Shield</Text>
              <Text style={styles.body}>¿Quién puede aparecer en tus recomendaciones?</Text>
              <Pressable
                onPress={() => setMode('other_gyms')}
                style={[styles.option, mode === 'other_gyms' && styles.optionSelected]}
                accessibilityRole="radio"
                accessibilityState={{ checked: mode === 'other_gyms' }}
              >
                <Text style={styles.optionTitle}>◉ Solo otros gimnasios</Text>
                <Text style={styles.body}>No ver personas de tu gimnasio habitual.</Text>
              </Pressable>
              <Pressable
                onPress={() => setMode('same_gym_other_time')}
                style={[styles.option, mode === 'same_gym_other_time' && styles.optionSelected]}
                accessibilityRole="radio"
                accessibilityState={{ checked: mode === 'same_gym_other_time' }}
              >
                <Text style={styles.optionTitle}>◷ Mismo gym, diferente horario</Text>
                <Text style={styles.body}>Permitir coincidencias sin cruces semanales, con 30 minutos de margen.</Text>
              </Pressable>
            </View>
            <Text style={styles.sectionTitle}>Perfiles de ejemplo · {matches.length}</Text>
            {matches.map((candidate) => (
              <View key={candidate.id} style={styles.person}>
                <View style={styles.avatar}><Text style={styles.avatarText}>{candidate.displayName[0]}</Text></View>
                <View style={styles.personBody}>
                  <Text style={styles.cardTitle}>{candidate.displayName}</Text>
                  <Text style={styles.body}>{candidate.sports}</Text>
                  <Text style={styles.secondary}>{candidate.city}</Text>
                </View>
                <Text style={styles.heart}>♡</Text>
              </View>
            ))}
            {matches.length === 0 && <Text style={styles.body}>No hay perfiles disponibles en esta demostración.</Text>}
            <Text style={styles.footnote}>Ningún horario o gimnasio individual se revela en la interfaz. Las exclusiones requieren implementación segura en servidor antes de lanzar.</Text>
          </>
        )}
      </ScrollView>

      <View style={styles.footer}>
        <Text style={styles.footerText}>PROTOTIPO MVP · v0.1.0</Text>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: '#091319' },
  header: { paddingHorizontal: 22, paddingTop: 18, paddingBottom: 18 },
  kicker: { fontSize: 10, letterSpacing: 2, color: '#9EB2BC', fontWeight: '700' },
  brand: { fontSize: 28, fontWeight: '800', letterSpacing: -0.9, color: '#F8FAFA', marginTop: 4 },
  accent: { color: '#B6F266' },
  subtitle: { marginTop: 5, color: '#B6C6CB', fontSize: 13 },
  tabs: { flexDirection: 'row', marginHorizontal: 17, backgroundColor: '#15252C', borderRadius: 14, padding: 4 },
  tab: { flex: 1, paddingVertical: 12, alignItems: 'center', borderRadius: 11 },
  tabActive: { backgroundColor: '#B6F266' },
  tabText: { color: '#BECBD0', fontWeight: '700', fontSize: 11 },
  tabTextActive: { color: '#101C20' },
  content: { padding: 20, paddingBottom: 30 },
  notice: { backgroundColor: '#26302C', padding: 10, borderRadius: 10, marginBottom: 16 },
  noticeText: { color: '#D5F9A1', fontSize: 10, fontWeight: '800', letterSpacing: 0.4 },
  sectionTitle: { color: '#F7FAFA', fontWeight: '800', fontSize: 21, marginBottom: 6 },
  lead: { color: '#B8C6CC', fontSize: 14, lineHeight: 21, marginBottom: 16 },
  card: { padding: 18, backgroundColor: '#16262D', borderRadius: 16, marginBottom: 12, borderColor: '#263B43', borderWidth: 1 },
  tag: { color: '#B6F266', fontWeight: '800', fontSize: 11, marginBottom: 9, letterSpacing: 1 },
  cardTitle: { color: '#F3F7F8', fontSize: 17, fontWeight: '800', marginBottom: 7 },
  body: { color: '#C4D0D5', fontSize: 13, lineHeight: 20 },
  secondary: { color: '#93A7AE', fontSize: 12 },
  option: { padding: 14, borderRadius: 11, marginTop: 12, borderColor: '#43525A', borderWidth: 1 },
  optionSelected: { borderColor: '#B6F266', backgroundColor: '#283B2B' },
  optionTitle: { color: '#F3F7F8', fontWeight: '800', marginBottom: 4, fontSize: 14 },
  person: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#16262D', borderRadius: 14, padding: 12, marginBottom: 10 },
  avatar: { backgroundColor: '#B6F266', height: 47, width: 47, borderRadius: 24, alignItems: 'center', justifyContent: 'center' },
  avatarText: { color: '#132022', fontSize: 23, fontWeight: '900' },
  personBody: { flex: 1, paddingHorizontal: 13 },
  heart: { color: '#B6F266', fontSize: 29 },
  footnote: { color: '#8CA1A9', fontSize: 11, lineHeight: 17, marginTop: 12 },
  footer: { paddingVertical: 10, alignItems: 'center', borderTopWidth: 1, borderTopColor: '#1A3038' },
  footerText: { color: '#718B94', fontWeight: '800', fontSize: 10, letterSpacing: 1 },
});
