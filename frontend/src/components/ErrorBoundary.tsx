import { Component, type ErrorInfo, type ReactNode } from 'react';

interface Props {
  children: ReactNode;
}

interface State {
  error: Error | null;
}

export default class ErrorBoundary extends Component<Props, State> {
  state: State = { error: null };

  static getDerivedStateFromError(error: Error): State {
    return { error };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error('[ErrorBoundary] render crash:', error, info.componentStack);
  }

  render() {
    if (this.state.error) {
      return (
        <div
          style={{
            minHeight: '100vh',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            padding: 24,
            background: '#0b0b0c',
            color: '#e6e6e6',
            fontFamily: 'Inter, system-ui, sans-serif',
            textAlign: 'center',
          }}
        >
          <div style={{ fontSize: 40, marginBottom: 12 }}>😬</div>
          <h1 style={{ fontSize: 22, fontWeight: 600, margin: '0 0 8px' }}>
            Something broke on this page.
          </h1>
          <p style={{ color: '#9aa0a6', maxWidth: 480, margin: '0 0 20px' }}>
            Refreshing usually fixes it. If it keeps happening, email{' '}
            <a href="mailto:support@zealova.com" style={{ color: '#34d399' }}>
              support@zealova.com
            </a>
            .
          </p>
          <button
            onClick={() => window.location.reload()}
            style={{
              padding: '10px 20px',
              borderRadius: 999,
              background: '#10b981',
              color: '#000',
              fontWeight: 600,
              border: 'none',
              cursor: 'pointer',
            }}
          >
            Reload page
          </button>
          <a
            href="/"
            style={{
              marginTop: 14,
              fontSize: 13,
              color: '#9aa0a6',
              textDecoration: 'underline',
            }}
          >
            Back to home
          </a>
        </div>
      );
    }
    return this.props.children;
  }
}
