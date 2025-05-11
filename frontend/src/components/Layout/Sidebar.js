import React from 'react';
import { NavLink } from 'react-router-dom';
import { 
  FaChartLine, 
  FaBed, 
  FaRunning, 
  FaHeartbeat, 
  FaCommentAlt,
  FaCalendarAlt,
  FaListAlt,
  FaTimes,
  FaVial
} from 'react-icons/fa';
import styles from './Sidebar.module.css';

const Sidebar = ({ isOpen, closeSidebar, hasDexcom }) => {
  return (
    <>
      {/* Mobile overlay */}
      <div 
        className={`${styles.overlay} ${isOpen ? styles.visible : ''}`} 
        onClick={closeSidebar}
        aria-hidden="true"
      ></div>
      
      {/* Sidebar */}
      <aside className={`${styles.sidebar} ${isOpen ? styles.open : ''}`}>
        <div className={styles.sidebarHeader}>
          <h2 className={styles.sidebarTitle}>Navigation</h2>
          <button 
            className={`${styles.closeButton} hide-on-desktop`}
            onClick={closeSidebar}
            aria-label="Close sidebar"
          >
            <FaTimes />
          </button>
        </div>
        
        <nav className={styles.navigation}>
          <NavLink 
            to="/dashboard"
            className={({ isActive }) => `${styles.navItem} ${isActive ? styles.active : ''}`}
            end
            onClick={closeSidebar}
          >
            <FaChartLine />
            <span>Dashboard</span>
          </NavLink>
          
          <NavLink 
            to="/dashboard/sleep"
            className={({ isActive }) => `${styles.navItem} ${isActive ? styles.active : ''}`}
            onClick={closeSidebar}
          >
            <FaBed />
            <span>Sleep</span>
          </NavLink>
          
          <NavLink 
            to="/dashboard/activity"
            className={({ isActive }) => `${styles.navItem} ${isActive ? styles.active : ''}`}
            onClick={closeSidebar}
          >
            <FaRunning />
            <span>Activity</span>
          </NavLink>
          
          <NavLink 
            to="/dashboard/readiness"
            className={({ isActive }) => `${styles.navItem} ${isActive ? styles.active : ''}`}
            onClick={closeSidebar}
          >
            <FaHeartbeat />
            <span>Readiness</span>
          </NavLink>
          
          {hasDexcom && (
            <NavLink 
              to="/dashboard/glucose"
              className={({ isActive }) => `${styles.navItem} ${isActive ? styles.active : ''}`}
              onClick={closeSidebar}
            >
              <FaVial />
              <span>Glucose</span>
            </NavLink>
          )}
          
          <div className={styles.divider}></div>
          
          <NavLink 
            to="/dashboard/journal"
            className={({ isActive }) => `${styles.navItem} ${isActive ? styles.active : ''}`}
            onClick={closeSidebar}
          >
            <FaCalendarAlt />
            <span>Journal</span>
          </NavLink>
          
          <NavLink 
            to="/dashboard/recommendations"
            className={({ isActive }) => `${styles.navItem} ${isActive ? styles.active : ''}`}
            onClick={closeSidebar}
          >
            <FaListAlt />
            <span>Recommendations</span>
          </NavLink>
          
          <NavLink 
            to="/dashboard/chat"
            className={({ isActive }) => `${styles.navItem} ${isActive ? styles.active : ''}`}
            onClick={closeSidebar}
          >
            <FaCommentAlt />
            <span>Chat</span>
          </NavLink>
        </nav>
      </aside>
    </>
  );
};

export default Sidebar; 