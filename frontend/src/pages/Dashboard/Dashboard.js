import React from 'react';
import { Routes, Route } from 'react-router-dom';
import DashboardHome from './DashboardHome';
import SleepPage from './SleepPage';
import ActivityPage from './ActivityPage';
import ReadinessPage from './ReadinessPage';
import GlucosePage from './GlucosePage';
import JournalPage from './JournalPage';
import RecommendationsPage from './RecommendationsPage';
import ChatPage from './ChatPage';
import { useAuth } from '../../context/AuthContext';
import NotFound from '../NotFound/NotFound';

const Dashboard = () => {
  const { dexcomStatus } = useAuth();

  return (
    <Routes>
      <Route path="/" element={<DashboardHome />} />
      <Route path="/sleep" element={<SleepPage />} />
      <Route path="/activity" element={<ActivityPage />} />
      <Route path="/readiness" element={<ReadinessPage />} />
      {dexcomStatus.isEnabled && (
        <Route path="/glucose" element={<GlucosePage />} />
      )}
      <Route path="/journal" element={<JournalPage />} />
      <Route path="/recommendations" element={<RecommendationsPage />} />
      <Route path="/chat" element={<ChatPage />} />
      <Route path="*" element={<NotFound />} />
    </Routes>
  );
};

export default Dashboard; 