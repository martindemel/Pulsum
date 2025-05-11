import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useData } from '../../context/DataContext';
import { useAuth } from '../../context/AuthContext';
import Header from './Header';
import Sidebar from './Sidebar';
import styles from './Layout.module.css';

const Layout = ({ children }) => {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const { syncData } = useData();
  const { dexcomStatus } = useAuth();
  const navigate = useNavigate();

  // Toggle sidebar on mobile
  const toggleSidebar = () => {
    setSidebarOpen(!sidebarOpen);
  };

  // Handle sync button click
  const handleSync = async () => {
    try {
      await syncData();
    } catch (error) {
      console.error('Sync failed:', error);
    }
  };

  // Navigate to developer tools
  const navigateToDeveloperTools = () => {
    navigate('/developer');
  };

  return (
    <div className={styles.layout}>
      <Header 
        toggleSidebar={toggleSidebar} 
        onSync={handleSync}
        onDeveloperTools={navigateToDeveloperTools}
      />
      
      <div className={styles.container}>
        <Sidebar 
          isOpen={sidebarOpen} 
          closeSidebar={() => setSidebarOpen(false)}
          hasDexcom={dexcomStatus.isEnabled}
        />
        
        <main className={styles.content}>
          {children}
        </main>
      </div>
    </div>
  );
};

export default Layout; 