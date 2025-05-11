import React, { useState } from 'react';
import { useData } from '../../context/DataContext';

const ChatPage = () => {
  const { chatHistory, loadingChat, sendChatMessage, clearChatHistory } = useData();
  const [message, setMessage] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!message.trim()) return;
    
    await sendChatMessage(message);
    setMessage('');
  };

  return (
    <div>
      <h1>AI Chat</h1>
      
      <div style={{ marginBottom: '20px' }}>
        <button onClick={clearChatHistory} disabled={loadingChat}>
          Clear Chat History
        </button>
      </div>
      
      <div style={{ 
        height: '400px', 
        overflowY: 'auto',
        border: '1px solid #ccc',
        padding: '10px',
        marginBottom: '20px'
      }}>
        {loadingChat ? (
          <div className="loading-container">
            <div className="loading-spinner"></div>
            <p>Loading chat history...</p>
          </div>
        ) : chatHistory && chatHistory.length > 0 ? (
          chatHistory.map((msg, index) => (
            <div 
              key={index}
              style={{
                padding: '8px 12px',
                margin: '8px 0',
                borderRadius: '8px',
                maxWidth: '80%',
                alignSelf: msg.role === 'user' ? 'flex-end' : 'flex-start',
                backgroundColor: msg.role === 'user' ? '#4C65FF' : '#F1F5F9',
                color: msg.role === 'user' ? 'white' : 'black',
                alignItems: msg.role === 'user' ? 'flex-end' : 'flex-start',
                marginLeft: msg.role === 'user' ? 'auto' : '0'
              }}
            >
              {msg.content}
            </div>
          ))
        ) : (
          <p>No messages yet. Start a conversation with the AI assistant.</p>
        )}
      </div>
      
      <form onSubmit={handleSubmit} style={{ display: 'flex' }}>
        <input
          type="text"
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          placeholder="Type your message..."
          style={{ flex: 1, padding: '10px', marginRight: '10px' }}
        />
        <button type="submit" disabled={!message.trim() || loadingChat}>
          Send
        </button>
      </form>
    </div>
  );
};

export default ChatPage; 