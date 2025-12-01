/**
 * DashboardLayout - Main layout wrapper for authenticated pages
 *
 * Features:
 * - Fixed sidebar on desktop (lg+)
 * - Responsive content area with proper margins
 * - Background decorations
 */
import { ReactNode } from 'react';
import Sidebar from './Sidebar';

interface DashboardLayoutProps {
  children: ReactNode;
  noPadding?: boolean;
}

export default function DashboardLayout({ children, noPadding = false }: DashboardLayoutProps) {
  return (
    <div className="min-h-screen bg-background">
      {/* Background decorations */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-0 right-0 w-[600px] h-[600px] bg-primary/5 rounded-full blur-[100px]" />
        <div className="absolute bottom-1/4 left-0 w-[500px] h-[500px] bg-secondary/5 rounded-full blur-[100px]" />
        <div className="absolute top-1/2 right-1/4 w-[400px] h-[400px] bg-accent/3 rounded-full blur-[80px]" />
      </div>

      {/* Sidebar - Desktop only */}
      <Sidebar />

      {/* Main content area */}
      <main className={`relative z-10 lg:ml-20 min-h-screen ${noPadding ? '' : 'p-4 lg:p-6'}`}>
        {children}
      </main>
    </div>
  );
}
