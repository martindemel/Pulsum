import React from 'react';
import { useData } from '../../context/DataContext';
import JournalEntry from '../../components/Journal/JournalEntry';

const JournalPage = () => {
  const { journalEntries, loadingJournal } = useData();

  return (
    <div>
      <h1>Journal</h1>
      
      <h2>New Entry</h2>
      <JournalEntry 
        initialEntry={null}
        loading={false}
        isCompact={false}
      />
      
      <h2>Past Entries</h2>
      {loadingJournal ? (
        <div className="loading-container">
          <div className="loading-spinner"></div>
          <p>Loading journal entries...</p>
        </div>
      ) : (
        <div>
          {journalEntries && journalEntries.length > 0 ? (
            <p>You have {journalEntries.length} journal entries.</p>
          ) : (
            <p>No journal entries yet. Start by creating your first entry above.</p>
          )}
        </div>
      )}
    </div>
  );
};

export default JournalPage; 