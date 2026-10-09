import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter, Route, Routes } from 'react-router-dom';
import './i18n';
import './styles.css';
import Widget from './routes/Widget';
import { WIDGET_PATH_PREFIX } from './lib/widget';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter>
      <Routes>
        <Route path={`${WIDGET_PATH_PREFIX}:id`} element={<Widget />} />
        <Route path="*" element={<Widget />} />
      </Routes>
    </BrowserRouter>
  </StrictMode>,
);
