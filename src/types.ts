export interface RiemannZero {
  n: number;
  gamma: number;
}

export interface EncryptedContainer {
  version: string;
  timestamp: number;
  layer1Schema: string; // Riemann XOR
  layer2Schema: string; // AES-256-GCM
  layer3Schema: string; // AES-256-CBC
  saltGcm: string;      // hex
  saltCbc: string;      // hex
  ivGcm: string;        // hex
  ivCbc: string;        // hex
  riemannOffset: number;
  payload: string;      // base64 encoded triple-encrypted data
  filename?: string;
  fileType?: string;
  fileSize?: number;
  isCapsule: boolean;
  unlockTimestamp?: number;
}

export interface KeyGenerationProfile {
  length: number;
  useUppers: boolean;
  useLowers: boolean;
  useNumbers: boolean;
  useSymbols: boolean;
  riemannSeed: number;
}

export interface TotpProfile {
  secret: string;
  issuer: string;
  account: string;
}

export interface SecurityEvent {
  id: string;
  timestamp: number;
  event: string;
  severity: 'info' | 'warning' | 'critical';
  details: string;
}
