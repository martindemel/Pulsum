import React from 'react';
import { Link } from 'react-router-dom';
import { FaBars, FaSync, FaTools } from 'react-icons/fa';
import styles from './Header.module.css';

const Header = ({ toggleSidebar, onSync, onDeveloperTools }) => {
  return (
    <header className={styles.header}>
      <div className={styles.headerContainer}>
        <div className={styles.leftSection}>
          <button 
            className={`${styles.menuButton} hide-on-desktop`}
            onClick={toggleSidebar}
            aria-label="Toggle menu"
          >
            <FaBars />
          </button>
          
          <Link to="/dashboard" className={styles.logo}>
            <h1>Pulsum</h1>
          </Link>
        </div>
        
        <div className={styles.rightSection}>
          <button 
            className={styles.actionButton}
            onClick={onSync}
            aria-label="Sync data"
            title="Sync data"
          >
            <FaSync />
            <span className="hide-on-mobile">Sync Now</span>
          </button>
          
          <button
            className={styles.actionButton}
            onClick={onDeveloperTools}
            aria-label="Developer tools"
            title="Developer tools"
          >
            <FaTools />
            <span className="hide-on-mobile">Developer</span>
          </button>
        </div>
      </div>
    </header>
  );
};

export default Header; 