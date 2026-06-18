import React from 'react';
import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer, Legend, CartesianGrid } from 'recharts';

interface BiometricActivityData {
  time: string;
  success: number;
  failed: number;
}

interface BiometricActivityChartProps {
  data: BiometricActivityData[];
  title?: string;
}

export const BiometricActivityChart: React.FC<BiometricActivityChartProps> = ({ 
  data, 
  title = "Biometric Activity" 
}) => {
  return (
    <div className="h-64 w-full bg-neutral-900 border border-neutral-850 p-4 rounded-xl">
      <h3 className="text-white text-xs font-mono font-bold uppercase tracking-wider mb-4">
        {title}
      </h3>
      <ResponsiveContainer width="100%" height="100%">
        <AreaChart data={data}>
          <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
          <XAxis dataKey="time" stroke="#94a3b8" fontSize={10} />
          <YAxis stroke="#94a3b8" fontSize={10} />
          <Tooltip 
            contentStyle={{ backgroundColor: '#171717', border: '1px solid #404040', borderRadius: '8px' }}
            itemStyle={{ fontSize: '10px' }}
          />
          <Legend wrapperStyle={{ fontSize: '10px' }} />
          <Area type="monotone" dataKey="success" stackId="1" stroke="#22c55e" fill="#22c55e" fillOpacity={0.2} />
          <Area type="monotone" dataKey="failed" stackId="1" stroke="#ef4444" fill="#ef4444" fillOpacity={0.2} />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
};
