import {
  CalledScreen,
  JoinScreen,
  MetricsScreen,
  PanelScreen,
  QrScreen,
  TicketScreen,
} from './screens';

export const SCREENS = {
  join: JoinScreen,
  ticket: TicketScreen,
  called: CalledScreen,
  qr: QrScreen,
  panel: PanelScreen,
  metrics: MetricsScreen,
} as const;

export type ScreenKey = keyof typeof SCREENS;
