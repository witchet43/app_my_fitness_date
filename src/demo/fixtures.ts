import type { DatingProfile } from '../domain/gymShield';

// Synthetic records ONLY. In production no gym IDs or schedules are sent to clients.
export const currentUser: DatingProfile = {
  id: 'me', displayName: 'Mi perfil', gymId: 'gym-norte', mode: 'other_gyms',
  datingEnabled: true, weeklySlots: [
    { day: 1, startMinutes: 420, endMinutes: 510 },
    { day: 3, startMinutes: 420, endMinutes: 510 },
    { day: 5, startMinutes: 420, endMinutes: 510 },
  ],
};

export const demoCandidates: Array<DatingProfile & { sports: string; city: string }> = [
  { id: 'c1', displayName: 'Alex', gymId: 'gym-sur', mode: 'other_gyms',
    datingEnabled: true, weeklySlots: [], sports: 'Running · Pesas', city: 'Querétaro' },
  { id: 'c2', displayName: 'Dani', gymId: 'gym-norte', mode: 'same_gym_other_time',
    datingEnabled: true, weeklySlots: [
      { day: 1, startMinutes: 1080, endMinutes: 1170 },
      { day: 3, startMinutes: 1080, endMinutes: 1170 },
    ], sports: 'HYROX · Fuerza', city: 'Querétaro' },
  { id: 'c3', displayName: 'Sam', gymId: 'gym-norte', mode: 'same_gym_other_time',
    datingEnabled: true, weeklySlots: [{ day: 1, startMinutes: 480, endMinutes: 570 }],
    sports: 'CrossFit · Ciclismo', city: 'Querétaro' },
  { id: 'c4', displayName: 'Chris', gymId: 'gym-centro', mode: 'other_gyms',
    datingEnabled: true, weeklySlots: [], sports: 'Ciclismo · Running', city: 'Querétaro' },
];

export const demoPosts = [
  { author: 'Comunidad Running', body: 'Este sábado: rodada ligera y café después del entrenamiento.', sport: 'RUNNING' },
  { author: 'Atletas Qro', body: '¿Quién más está preparando su siguiente competencia funcional?', sport: 'FUERZA' },
];

export const demoActivities = [
  { title: 'Running social', detail: 'Parque público · Sábado · Actividad de ejemplo', sport: 'RUNNING' },
  { title: 'Entrenamiento funcional', detail: 'Grupo abierto · Domingo · Actividad de ejemplo', sport: 'FUNCIONAL' },
];
