/**
 * AdminLayout - Main layout wrapper for admin dashboard pages
 *
 * Features:
 * - Collapsible sidebar with navigation
 * - Top header with user info and notifications
 * - Background decorations matching main app style
 */
import { type ReactNode } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useAdminStore } from '../../store/adminStore';

interface AdminLayoutProps {
  children: ReactNode;
}

const navItems = [
  {
    path: '/admin/dashboard',
    label: 'Dashboard',
    icon: (
      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />
      </svg>
    ),
  },
  {
    path: '/admin/chats',
    label: 'Live Chats',
    icon: (
      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
      </svg>
    ),
  },
];

export default function AdminLayout({ children }: AdminLayoutProps) {
  const location = useLocation();
  const navigate = useNavigate();
  const { session, logout, sidebarCollapsed, setSidebarCollapsed, stats } = useAdminStore();

  const handleLogout = () => {
    logout();
    navigate('/admin/login');
  };

  return (
    <div className="min-h-screen bg-background">
      {/* Background decorations */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-0 right-0 w-[600px] h-[600px] bg-primary/5 rounded-full blur-[100px]" />
        <div className="absolute bottom-1/4 left-0 w-[500px] h-[500px] bg-secondary/5 rounded-full blur-[100px]" />
        <div className="absolute top-1/2 right-1/4 w-[400px] h-[400px] bg-accent/3 rounded-full blur-[80px]" />
      </div>

      {/* Sidebar */}
      <aside
        className={`fixed left-0 top-0 z-40 h-screen transition-all duration-300 ${
          sidebarCollapsed ? 'w-20' : 'w-64'
        }`}
      >
        <div className="h-full glass-card flex flex-col border-r border-white/10">
          {/* Logo */}
          <div className="p-4 border-b border-white/10 flex items-center justify-between">
            {!sidebarCollapsed && (
              <span className="text-xl font-bold bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent">
                FitWiz Admin
              </span>
            )}
            <button
              onClick={() => setSidebarCollapsed(!sidebarCollapsed)}
              className="p-2 rounded-lg hover:bg-white/10 transition-colors"
            >
              <svg
                className={`w-5 h-5 text-text-secondary transition-transform ${
                  sidebarCollapsed ? 'rotate-180' : ''
                }`}
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 19l-7-7 7-7m8 14l-7-7 7-7" />
              </svg>
            </button>
          </div>

          {/* Navigation */}
          <nav className="flex-1 p-4 space-y-2">
            {navItems.map((item) => {
              const isActive = location.pathname === item.path;
              return (
                <Link
                  key={item.path}
                  to={item.path}
                  className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all ${
                    isActive
                      ? 'bg-primary/20 text-primary border border-primary/30'
                      : 'text-text-secondary hover:bg-white/5 hover:text-text'
                  }`}
                >
                  {item.icon}
                  {!sidebarCollapsed && <span>{item.label}</span>}
                  {!sidebarCollapsed && item.path === '/admin/chats' && stats && stats.queue_size > 0 && (
                    <span className="ml-auto bg-orange-500 text-white text-xs px-2 py-0.5 rounded-full">
                      {stats.queue_size}
                    </span>
                  )}
                </Link>
              );
            })}
          </nav>

          {/* User Info */}
          <div className="p-4 border-t border-white/10">
            <div className={`flex items-center ${sidebarCollapsed ? 'justify-center' : 'gap-3'}`}>
              <div className="w-10 h-10 rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center text-white font-semibold">
                {session?.user.name.charAt(0).toUpperCase()}
              </div>
              {!sidebarCollapsed && (
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-text truncate">{session?.user.name}</p>
                  <p className="text-xs text-text-muted capitalize">{session?.user.role.replace('_', ' ')}</p>
                </div>
              )}
              {!sidebarCollapsed && (
                <button
                  onClick={handleLogout}
                  className="p-2 rounded-lg hover:bg-white/10 transition-colors text-text-secondary hover:text-coral"
                  title="Logout"
                >
                  <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                  </svg>
                </button>
              )}
            </div>
          </div>
        </div>
      </aside>

      {/* Main content area */}
      <main
        className={`relative z-10 min-h-screen transition-all duration-300 ${
          sidebarCollapsed ? 'ml-20' : 'ml-64'
        }`}
      >
        {/* Header */}
        <header className="sticky top-0 z-30 glass border-b border-white/10 px-6 py-4">
          <div className="flex items-center justify-between">
            <h1 className="text-xl font-semibold text-text">
              {navItems.find((item) => item.path === location.pathname)?.label || 'Admin'}
            </h1>
            <div className="flex items-center gap-4">
              {/* Online Status Indicator */}
              <div className="flex items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
                <span className="text-sm text-text-secondary">Online</span>
              </div>
              {/* Quick Stats */}
              {stats && (
                <div className="flex items-center gap-4 text-sm">
                  <div className="flex items-center gap-2 text-text-secondary">
                    <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                    </svg>
                    <span>{stats.online_agents} agents</span>
                  </div>
                </div>
              )}
            </div>
          </div>
        </header>

        {/* Page content */}
        <div className="p-6">
          {children}
        </div>
      </main>
    </div>
  );
}
