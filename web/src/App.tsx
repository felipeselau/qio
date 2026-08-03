import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import QueuePage from './routes/QueuePage';

export default function App() {
  return (
    <div className="app-shell">
      <BrowserRouter>
        <Routes>
          <Route path="/q/:queueId" element={<QueuePage />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </div>
  );
}