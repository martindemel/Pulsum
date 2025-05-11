import React, { useState, useRef, useEffect, useCallback } from 'react';
import { useData } from '../../context/DataContext';
import { FaPaperPlane, FaTimes, FaRobot } from 'react-icons/fa';
import styles from './ChatWidget.module.css';
import { debounce } from '../../utils/helpers';

// Add diagnostic console log on component load
console.log('ChatWidget loading');

const ChatWidget = ({ isCompact = true }) => {
  const { chatHistory, loadingChat, sendChatMessage } = useData();
  const [message, setMessage] = useState('');
  const [isOpen, setIsOpen] = useState(false);
  const [localChatHistory, setLocalChatHistory] = useState([]);
  const [isSending, setIsSending] = useState(false);
  const chatContainerRef = useRef(null);

  console.log('ChatWidget rendered', { 
    chatHistoryLength: chatHistory?.length, 
    localChatHistoryLength: localChatHistory?.length,
    loadingChat,
    isSending
  });

  // Update local chat history when the global one changes
  useEffect(() => {
    console.log('chatHistory changed', { 
      chatHistoryLength: chatHistory?.length
    });
    
    if (chatHistory) {
      setLocalChatHistory(chatHistory);
    }
  }, [chatHistory]);

  // Scroll to bottom when new messages arrive
  useEffect(() => {
    if (chatContainerRef.current) {
      chatContainerRef.current.scrollTop = chatContainerRef.current.scrollHeight;
    }
  }, [localChatHistory]);

  // Debounced message setter to improve performance during typing
  const debouncedSetMessage = useCallback(
    debounce((value) => setMessage(value), 100),
    []
  );

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!message.trim() || isSending) return;
    
    const userMessage = message.trim();
    setMessage('');
    setIsSending(true);
    
    console.log('Sending message:', userMessage);
    
    // Optimistic UI update
    const tempId = Date.now();
    const optimisticMessage = { id: tempId, role: 'user', content: userMessage };
    setLocalChatHistory(prev => [...prev, optimisticMessage]);
    
    try {
      console.log('Calling sendChatMessage...');
      const response = await sendChatMessage(userMessage);
      console.log('Response received:', response);
      // The actual response will be added to chatHistory by the DataContext
    } catch (error) {
      console.error('Failed to send message:', error);
      // Show error in chat
      setLocalChatHistory(prev => [
        ...prev, 
        { id: tempId + 1, role: 'assistant', content: 'Sorry, I couldn\'t send your message. Please try again.' }
      ]);
    } finally {
      setIsSending(false);
    }
  };

  const toggleWidget = () => {
    setIsOpen(prev => !prev);
  };

  // Get the last message for compact view
  const lastMessage = localChatHistory && localChatHistory.length > 0 
    ? localChatHistory[localChatHistory.length - 1] 
    : null;

  // If compact and dashboard integrated (not popup mode)
  if (isCompact && !isOpen) {
    return (
      <div className={styles.dashboardChat}>
        <div className={styles.dashboardChatPreview}>
          {lastMessage ? (
            <div className={styles.lastMessage}>
              <div className={styles.messageIcon}>
                {lastMessage.role === 'user' ? 'You:' : <FaRobot />}
              </div>
              <p>{lastMessage.content.length > 60 
                ? lastMessage.content.substring(0, 60) + '...' 
                : lastMessage.content}</p>
            </div>
          ) : (
            <div className={styles.welcome}>
              <p>Ask me a question about your health data or wellness recommendations!</p>
            </div>
          )}
        </div>
        <form className={styles.dashboardInputForm} onSubmit={handleSubmit}>
          <input
            type="text"
            value={message}
            onChange={(e) => debouncedSetMessage(e.target.value)}
            placeholder="Type your message..."
            disabled={isSending || loadingChat}
            className={isSending ? styles.inputDisabled : ''}
          />
          <button 
            type="submit" 
            disabled={!message.trim() || isSending || loadingChat}
            className={isSending ? styles.buttonSending : ''}
          >
            <FaPaperPlane />
          </button>
        </form>
        {(isSending || loadingChat) && <div className={styles.miniLoader}></div>}
      </div>
    );
  }

  // Full chat view (popup or expanded)
  return (
    <div className={`${styles.chatWidget} ${isCompact ? styles.compact : ''}`}>
      <div className={styles.header}>
        <h3>AI Assistant</h3>
        {isCompact && (
          <button className={styles.closeButton} onClick={toggleWidget}>
            <FaTimes />
          </button>
        )}
      </div>
      
      <div className={styles.chatContainer} ref={chatContainerRef}>
        {loadingChat && localChatHistory.length === 0 ? (
          <div className={styles.loading}>
            <div className={styles.loadingSpinner}></div>
            <p>Loading chat...</p>
          </div>
        ) : !localChatHistory || localChatHistory.length === 0 ? (
          <div className={styles.welcome}>
            <p>Hi there! I'm your Pulsum AI Assistant. I can help you understand your health data, recommend wellness activities, and answer your health-related questions.</p>
            <p>How can I help you today?</p>
          </div>
        ) : (
          localChatHistory.map((msg, index) => (
            <div 
              key={msg.id || index}
              className={`${styles.message} ${msg.role === 'user' ? styles.user : styles.assistant} ${isSending && index === localChatHistory.length - 1 && msg.role === 'user' ? styles.sending : ''}`}
            >
              {msg.content}
              {isSending && index === localChatHistory.length - 1 && msg.role === 'user' && (
                <span className={styles.statusIndicator}>Sending...</span>
              )}
            </div>
          ))
        )}
        {isSending && (
          <div className={styles.typingIndicator}>
            <span></span>
            <span></span>
            <span></span>
          </div>
        )}
      </div>
      
      <form className={styles.inputForm} onSubmit={handleSubmit}>
        <input
          type="text"
          value={message}
          onChange={(e) => debouncedSetMessage(e.target.value)}
          placeholder="Type your message..."
          disabled={isSending || loadingChat}
          className={isSending ? styles.inputDisabled : ''}
        />
        <button 
          type="submit" 
          disabled={!message.trim() || isSending || loadingChat}
          className={isSending ? styles.buttonSending : ''}
        >
          <FaPaperPlane />
        </button>
      </form>
    </div>
  );
};

export default ChatWidget; 