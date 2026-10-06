import { BrowserRouter, Routes, Route } from 'react-router-dom';
import QueuePage from './routes/QueuePage';
import { useTheme } from './lib/theme';

function NotFound() {
  return (
    <div className="center-col">
      <h1 style={{ fontSize: 20, fontWeight: 700 }}>Link inválido</h1>
      <p className="muted">Escaneie o QR code da fila para entrar.</p>
    </div>
  );
}

export default function App() {
  const { theme, toggle } = useTheme();
  return (
    <div className="app-shell">
      <button
        type="button"
        className="theme-toggle"
        onClick={toggle}
        aria-label={theme === 'dark' ? 'Usar tema claro' : 'Usar tema escuro'}
      >
        {theme === 'dark' ? '☀️' : '🌙'}
      </button>
      <BrowserRouter>
        <Routes>
          <Route path="/q/:queueId" element={<QueuePage />} />
          <Route path="*" element={<NotFound />} />
        </Routes>
      </BrowserRouter>
    </div>
  );
}
