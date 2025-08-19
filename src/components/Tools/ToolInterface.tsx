// @ts-nocheck - Suppress TypeScript errors for implicit any types in state update functions
import React, { useState, useEffect, useRef } from 'react';
import { ArrowLeft, Play, Square, Download, Trash2, FileText, Merge } from 'lucide-react';
import { Tool } from '../../types';
import io, { Socket } from 'socket.io-client';
import { API_CONFIG, getApiUrl, getWsUrl } from '../../config/api';
import { useToolState } from '../../contexts/ToolStateContext';
import { GemToolState } from '../../contexts/ToolStateContext';
// import { useGemTool } from '../../contexts/GemToolContext';
import LiveLogViewer from './LiveLogViewer';

async function fetchFileSize(url: string): Promise<string> {
  try {
    console.log('🔍 Fetching file size for:', url);
    const res = await fetch(url, { method: 'HEAD' });
    console.log('📊 File size response status:', res.status);
    if (res.ok) {
      const size = res.headers.get('content-length');
      console.log('📏 Content-Length header:', size);
      if (size) {
        const bytes = parseInt(size);
        if (bytes < 1024) return `${bytes} B`;
        if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
        return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
      }
    } else {
      console.log('❌ File size request failed with status:', res.status);
    }
  } catch (error) {
    console.log('Error fetching file size:', error);
  }
  return 'Unknown size';
}

interface ToolInterfaceProps {
  tool: Tool;
  onBack: () => void;
}

interface ToolState {
  inputValues: { [key: string]: string };
  log: string;
  isRunning: boolean;
  isScrapingComplete: boolean;
  runId: string | null;
  outputFiles: string[];
  socket: any;
  selectedState: string | null;
  selectedCity: string;
  activeJobState: string | null;
  jobData: Record<string, any>;
  scrapingJobs: { state: string, status: 'in-progress' | 'complete' }[];
  stopMessage: string;
  isStopping: boolean;
  pollInterval?: NodeJS.Timeout;
}

// Defensive utility to ensure only the file name is used
function getFileNameOnly(file: string) {
  return file.split(/[\\/]/).pop() || file;
}

interface EProcRun {
  id: string;
  sessionId: string;
  baseUrl: string;
  tenderType: string;
  daysInterval: string;
  startPage: string;
  captcha: string;
  status: 'running' | 'completed' | 'stopped' | 'error';
  startTime: Date;
  endTime?: Date;
  outputFiles: string[];
  isActive: boolean;
}

export const ToolInterface: React.FC<ToolInterfaceProps> = ({ tool, onBack }) => {
  // Use context state for GEM tool, local state for others
  const { state: toolState, setState: setToolState } = useToolState();
  
  // Simplified state management - use local state for all tools
  const [state, setState] = useState<any>({
    inputValues: {},
    log: '',
    isRunning: false,
    isScrapingComplete: false,
    runId: null,
    outputFiles: [],
    socket: null,
    selectedState: null,
    selectedCity: '',
    activeJobState: null,
    jobData: {},
    scrapingJobs: [],
    stopMessage: '',
    isStopping: false,
    sockets: {} // Store separate sockets for each state
  });

  // For GEM tool, use context state
  const isGem = tool.name === 'gem';
  const gemState = isGem ? toolState.gem : null;
  const setGemState = isGem ? (updater: any) => setToolState(prev => ({ ...prev, gem: updater(prev.gem) })) : null;
  
  // Move activeJobState to context
  const activeJobState = isGem ? gemState?.activeJobState : state.activeJobState;
  const setActiveJobState = (jobState: string | null) => {
    if (isGem && setGemState) {
      setGemState((prev: any) => ({ ...prev, activeJobState: jobState }));
    } else {
    setState((prev: any) => ({ ...prev, activeJobState: jobState }));
    }
  };

  // On mount or when jobs change, set activeJobState if not set
  useEffect(() => {
    if (isGem && !state.activeJobState && state.scrapingJobs && state.scrapingJobs.length > 0) {
      // Prefer running job, else most recent
      const runningJob = state.scrapingJobs.find((j: any) => j.status === 'in-progress');
      setActiveJobState(runningJob ? runningJob.state : state.scrapingJobs[0].state);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isGem, state.activeJobState, state.scrapingJobs]);

  // For Gem Tool, use context state; for others, use local state
  const [showCaptchaReminder, setShowCaptchaReminder] = useState(false);
  const [eStep, setEStep] = useState<'start' | 'captcha'>('start');

  // Add scrapingJobs state
  const [scrapingJobs, setScrapingJobs] = useState<{ state: string, status: 'in-progress' | 'complete' }[]>([]);
  
  // For GEM tool, use context state for scrapingJobs
  const getScrapingJobs = () => {
    return isGem && gemState ? gemState.scrapingJobs : scrapingJobs;
  };
  
  const setScrapingJobsWrapper = (updater: any) => {
    if (isGem && setGemState) {
      setGemState((prev: any) => ({ ...prev, scrapingJobs: updater(prev.scrapingJobs) }));
    } else {
      setScrapingJobs(updater);
    }
  };
  // Remove local jobData state
  // const [jobData, setJobData] = useState<Record<string, {
  //   inputValues: { [key: string]: string },
  //   selectedCity: string,
  //   log: string,
  //   isRunning: boolean,
  //   isScrapingComplete: boolean,
  //   runId: string | null,
  //   outputFiles: string[],
  //   stopMessage: string
  // }>>({});
  // Use context for jobData
  const jobData = isGem ? gemState?.jobData : state.jobData;
  const setJobData = (updater: (prev: typeof jobData) => typeof jobData) => {
    if (isGem && setGemState) {
      setGemState((prev: any) => ({ ...prev, jobData: updater(prev.jobData) }));
    } else {
    setState((prev: any) => ({ ...prev, jobData: updater(prev.jobData) }));
    }
  };

  // Add validStates array at the top (should match backend order)
  const validStates = [
    "ANDAMAN & NICOBAR",
    "ANDHRA PRADESH",
    "ARUNACHAL PRADESH",
    "ASSAM",
    "BIHAR",
    "CHANDIGARH",
    "CHHATTISGARH",
    "DADRA & NAGAR HAVELI",
    "DAMAN & DIU",
    "DELHI",
    "GOA",
    "GUJARAT",
    "HARYANA",
    "HIMACHAL PRADESH",
    "JAMMU & KASHMIR",
    "JHARKHAND",
    "KARNATAKA",
    "KERALA",
    "LAKSHADWEEP",
    "MADHYA PRADESH",
    "MAHARASHTRA",
    "MANIPUR",
    "MEGHALAYA",
    "MIZORAM",
    "NAGALAND",
    "ODISHA",
    "PUDUCHERRY",
    "PUNJAB",
    "RAJASTHAN",
    "SIKKIM",
    "TAMIL NADU",
    "TELANGANA",
    "TRIPURA",
    "UTTAR PRADESH",
    "UTTARAKHAND",
    "WEST BENGAL"
  ];

  // E-Procurement specific state
  const [eBaseUrl, setEBaseUrl] = useState('');
  const [eTenderType, setETenderType] = useState('');
  const [eDaysInterval, setEDaysInterval] = useState('');
  const [eStartPage, setEStartPage] = useState('');
  const [eCaptcha, setECaptcha] = useState('');
  const [eIsRunning, setEIsRunning] = useState(false);
  const [eScrapingStarted, setEScrapingStarted] = useState(false);
  const [eError, setEError] = useState('');
  const [eSuccess, setESuccess] = useState('');
  const [edgeOpened, setEdgeOpened] = useState(false);
  const [eOutputFiles, setEOutputFiles] = useState<string[]>([]);
  const [eCurrentSessionId, setECurrentSessionId] = useState<string | null>(null);
  
  // NEW: Multiple runs support
  const [eProcRuns, setEProcRuns] = useState<EProcRun[]>([]);
  const [activeRunId, setActiveRunId] = useState<string | null>(null);

  // WebSocket connection for E-Procurement
  const [eSocket, setESocket] = useState<any>(null);

  // Backend configuration
  const BACKEND_URL = getApiUrl('eproc');
  const WS_URL = getWsUrl('scraper');

  useEffect(() => {
    if (tool.name === 'gem' && tool.inputs) {
      const initialInputs: { [key: string]: string } = {};
      tool.inputs.forEach(input => {
        initialInputs[input.name] = input.default ? String(input.default) : '';
      });
      // Only set if inputValues is empty (first load)
      if (!state.inputValues || Object.keys(state.inputValues).length === 0) {
        setState((prev: any) => ({ ...prev, inputValues: initialInputs }));
      }
    }
    // Only depend on tool.name and tool.inputs
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tool.name, tool.inputs]);

  // Defensive: ensure inputValues exists for non-gem tools
  useEffect(() => {
    if (!isGem && !state.inputValues) {
      setState({ inputValues: {} });
    }
  }, [isGem, state.inputValues]);

  // Add WebSocket event listener for instant output file updates
  useEffect(() => {
    // Set up event handlers for all active sockets
    const setupSocketHandlers = (socket: any, stateName: string) => {
      if (!socket) return;
      
      console.log(`🔌 Setting up WebSocket event listeners for state: ${stateName}`);
      
      const handleFileWritten = (data: { filename: string, run_id: string }) => {
        console.log(`📁 File written event received for ${stateName}:`, data);
        // Extract just the filename from the full path if needed
        const filename = data.filename.includes('/') || data.filename.includes('\\') 
          ? data.filename.split(/[/\\]/).pop() || data.filename 
          : data.filename;
        
        // Update job-specific state
        if (isGem && setGemState) {
          setGemState((prev: any) => ({
            ...prev,
            jobData: {
              ...prev.jobData,
              [stateName]: {
                ...prev.jobData[stateName],
                outputFiles: prev.jobData[stateName]?.outputFiles && !prev.jobData[stateName].outputFiles.includes(filename)
                  ? [...prev.jobData[stateName].outputFiles, filename]
                  : prev.jobData[stateName]?.outputFiles || [filename]
              }
            }
          }));
        } else {
          setJobData((prev: any) => ({
            ...prev,
            [stateName]: {
              ...prev[stateName],
              outputFiles: prev[stateName]?.outputFiles && !prev[stateName].outputFiles.includes(filename)
                ? [...prev[stateName].outputFiles, filename]
                : prev[stateName]?.outputFiles || [filename]
            }
          }));
        }
        
        // Also update global state if this is the active job
        if (activeJobState === stateName) {
          if (isGem && setGemState) {
            setGemState((prev: any) => ({
              ...prev,
              outputFiles: prev.outputFiles && !prev.outputFiles.includes(filename)
                ? [...prev.outputFiles, filename]
                : prev.outputFiles || [filename]
            }));
          } else {
            setState((prev: any) => ({
              ...prev,
              outputFiles: prev.outputFiles && !prev.outputFiles.includes(filename)
                ? [...prev.outputFiles, filename]
                : prev.outputFiles || [filename]
            }));
          }
        }
      };
      
      const handleScrapingOutput = (data: { output: string }) => {
        console.log(`📝 Scraping output received for ${stateName}:`, data.output);
        
        // Update job-specific state
        if (isGem && setGemState) {
          setGemState((prev: any) => ({
            ...prev,
            jobData: {
              ...prev.jobData,
              [stateName]: {
                ...prev.jobData[stateName],
                log: (prev.jobData[stateName]?.log || '') + data.output + '\n',
                isRunning: data.output.includes('SCRAPING COMPLETED') ? false : true,
                isScrapingComplete: data.output.includes('SCRAPING COMPLETED') ? true : prev.jobData[stateName]?.isScrapingComplete
              }
            }
          }));
        } else {
          setJobData((prev: any) => {
            const job = prev[stateName] || {};
            return {
              ...prev,
              [stateName]: {
                ...job,
                log: (job.log || '') + data.output + '\n',
                isRunning: data.output.includes('SCRAPING COMPLETED') ? false : true,
                isScrapingComplete: data.output.includes('SCRAPING COMPLETED') ? true : job.isScrapingComplete
              }
            };
          });
        }
        
        // Also update global state if this is the active job
        if (activeJobState === stateName) {
          if (isGem && setGemState) {
            setGemState((prev: any) => ({
              ...prev,
              log: (prev.log || '') + data.output + '\n',
              isRunning: data.output.includes('SCRAPING COMPLETED') ? false : true,
              isScrapingComplete: data.output.includes('SCRAPING COMPLETED') ? true : prev.isScrapingComplete
            }));
          } else {
            setState((prev: any) => ({
              ...prev,
              log: (prev.log || '') + data.output + '\n',
              isRunning: data.output.includes('SCRAPING COMPLETED') ? false : true,
              isScrapingComplete: data.output.includes('SCRAPING COMPLETED') ? true : prev.isScrapingComplete
            }));
          }
        }
        
        // Update scrapingJobs status when scraping completes
        if (data.output.includes('SCRAPING COMPLETED')) {
          setScrapingJobsWrapper(jobs => 
            jobs.map(job => 
              job.state === stateName 
                ? { ...job, status: 'complete' as const }
                : job
            )
          );
        }
      };

      const handleOutput = (data: string) => {
        console.log(`📝 Raw output received for ${stateName}:`, data);
        
        // Update job-specific state
        setJobData((prev: any) => {
          const job = prev[stateName] || {};
          return {
            ...prev,
            [stateName]: {
              ...job,
              log: (job.log || '') + data + '\n',
              isRunning: data.includes('SCRAPING COMPLETED') ? false : true,
              isScrapingComplete: data.includes('SCRAPING COMPLETED') ? true : job.isScrapingComplete
            }
          };
        });
        
        // Also update global state if this is the active job
        if (activeJobState === stateName) {
          setState((prev: any) => ({
            ...prev,
            log: (prev.log || '') + data + '\n',
            isRunning: data.includes('SCRAPING COMPLETED') ? false : true,
            isScrapingComplete: data.includes('SCRAPING COMPLETED') ? true : prev.isScrapingComplete
          }));
        }
        
        // Update scrapingJobs status when scraping completes
        if (data.includes('SCRAPING COMPLETED')) {
          setScrapingJobsWrapper(jobs => 
            jobs.map(job => 
              job.state === stateName 
                ? { ...job, status: 'complete' as const }
                : job
            )
          );
        }
      };
      
      socket.on('file_written', handleFileWritten);
      socket.on('scraping_output', handleScrapingOutput);
      socket.on('output', handleOutput);
      socket.on('message', (data: any) => {
        console.log(`📨 Raw message received for ${stateName}:`, data);
        if (typeof data === 'string' && data.startsWith('OUTPUT:')) {
          handleOutput(data);
        }
      });
      
      // Return cleanup function
      return () => {
        console.log(`🔌 Cleaning up WebSocket event listeners for ${stateName}`);
        socket.off('file_written', handleFileWritten);
        socket.off('scraping_output', handleScrapingOutput);
        socket.off('output', handleOutput);
        socket.off('message');
      };
    };
    
    // Set up handlers for all active sockets
    const cleanupFunctions: (() => void)[] = [];
    const socketsToUse = isGem && gemState ? gemState.sockets : state.sockets;
    Object.entries(socketsToUse || {}).forEach(([stateName, socket]) => {
      const cleanup = setupSocketHandlers(socket, stateName);
      if (cleanup) cleanupFunctions.push(cleanup);
    });
    
    // Set up polling for output files when scraping is running
    let pollInterval: NodeJS.Timeout | null = null;
    if (state.isRunning && state.runId) {
      pollInterval = setInterval(async () => {
        try {
          const response = await fetch(`${API_CONFIG.FILE_MANAGER_API}/api/files/${state.runId}`);
          if (response.ok) {
            const files = await response.json();
            setState((prev: any) => ({
              ...prev,
              outputFiles: files
            }));
          }
        } catch (error) {
          console.log('Polling for files failed:', error);
        }
      }, 2000); // Poll every 2 seconds
    }
      
      const handleFileWritten = (data: { filename: string, run_id: string }) => {
        console.log('📁 Global file_written event received:', data);
        // Extract just the filename from the full path if needed
        const filename = data.filename.includes('/') || data.filename.includes('\\') 
          ? data.filename.split(/[/\\]/).pop() || data.filename 
          : data.filename;
        
        // Always update global state
        setState((prev: any) => ({
          ...prev,
          outputFiles: prev.outputFiles && !prev.outputFiles.includes(filename)
            ? [...prev.outputFiles, filename]
            : prev.outputFiles || [filename]
        }));
        
        // Also update job-specific state if we have an active job
        if (activeJobState) {
          setJobData((prev: any) => ({
            ...prev,
            [activeJobState]: {
              ...prev[activeJobState],
              outputFiles: prev[activeJobState]?.outputFiles && !prev[activeJobState].outputFiles.includes(filename)
                ? [...prev[activeJobState].outputFiles, filename]
                : prev[activeJobState]?.outputFiles || [filename]
            }
          }));
        }
      };
      
      const handleScrapingOutput = (data: { output: string }) => {
        console.log('📝 Global scraping_output event received:', data.output);
        
        // Always update global state
        setState((prev: any) => ({
          ...prev,
          log: (prev.log || '') + data.output + '\n',
          isRunning: data.output.includes('SCRAPING COMPLETED') ? false : true,
          isScrapingComplete: data.output.includes('SCRAPING COMPLETED') ? true : prev.isScrapingComplete
        }));
        
        // Also update job-specific state if we have an active job
        if (activeJobState) {
          setJobData((prev: any) => {
            const job = prev[activeJobState] || {};
            return {
              ...prev,
              [activeJobState]: {
                ...job,
                log: (job.log || '') + data.output + '\n',
                isRunning: data.output.includes('SCRAPING COMPLETED') ? false : true,
                isScrapingComplete: data.output.includes('SCRAPING COMPLETED') ? true : job.isScrapingComplete
              }
            };
          });
          
          // Update scrapingJobs status when scraping completes
          if (data.output.includes('SCRAPING COMPLETED')) {
            setScrapingJobs(jobs => 
              jobs.map(job => 
                job.state === activeJobState 
                  ? { ...job, status: 'complete' as const }
                  : job
              )
            );
          }
        }
      };

      // Handle raw output messages (for backend that sends OUTPUT: messages)
      const handleOutput = (data: string) => {
        console.log('📝 Raw output received:', data);
        
        setState((prev: any) => ({
          ...prev,
          log: (prev.log || '') + data + '\n',
          isRunning: data.includes('SCRAPING COMPLETED') ? false : true,
          isScrapingComplete: data.includes('SCRAPING COMPLETED') ? true : prev.isScrapingComplete
        }));
        
        if (activeJobState) {
          setJobData((prev: any) => {
            const job = prev[activeJobState] || {};
            return {
              ...prev,
              [activeJobState]: {
                ...job,
                log: (job.log || '') + data + '\n',
                isRunning: data.includes('SCRAPING COMPLETED') ? false : true,
                isScrapingComplete: data.includes('SCRAPING COMPLETED') ? true : job.isScrapingComplete
              }
            };
          });
          
          // Update scrapingJobs status when scraping completes
          if (data.includes('SCRAPING COMPLETED')) {
            setScrapingJobs(jobs => 
              jobs.map(job => 
                job.state === activeJobState 
                  ? { ...job, status: 'complete' as const }
                  : job
              )
            );
          }
        }
      };
      
      return () => {
        console.log('🔌 Cleaning up WebSocket event listeners');
        
        // Clean up all socket handlers
        cleanupFunctions.forEach(cleanup => cleanup());
        
        // Clean up polling interval
        if (pollInterval) {
          clearInterval(pollInterval);
        }
      };
  }, [isGem ? gemState?.sockets : state.sockets, activeJobState]);

  // Replace all useState for Gem Tool with context state
  // Example: state.inputValues, state.selectedState, etc.
  // Replace setInputValues, setSelectedState, etc. with setState updater

  // Input change handler for all tools - memoized for performance
  const handleInputChange = React.useCallback((name: string, value: string) => {
    console.log('Input change:', name, value);
    setState((prev: any) => ({
      ...prev,
      inputValues: {
        ...prev.inputValues,
        [name]: value
      }
    }));
    
    // Update job data if we have an active job
    if (activeJobState) {
      setJobData((prev: any) => ({
        ...prev,
        [activeJobState]: {
          ...prev[activeJobState],
          inputValues: {
            ...prev[activeJobState]?.inputValues,
            [name]: value
          }
        }
      }));
    }
  }, [activeJobState, setJobData]);

  // Example for state selection:
  // setState(prev => ({ ...prev, selectedState: value }));

  // Example for log update:
  // setState(prev => ({ ...prev, log: prev.log + newLog }));

  // Example for output files:
  // setState(prev => ({ ...prev, outputFiles: [...prev.outputFiles, file] }));

  // All other Gem Tool state (isRunning, runId, etc.) should use context

  // Add state for IREPS session
  const [irepsSessionId, setIrepsSessionId] = useState<string | null>(null);
  const [chromeOpened, setChromeOpened] = useState(false);
  const [openChromeLoading, setOpenChromeLoading] = useState(false);
  const [openChromeError, setOpenChromeError] = useState('');

  // Handler to open Chrome for IREPS
  const handleOpenChrome = async () => {
    setOpenChromeLoading(true);
    setOpenChromeError('');
    try {
      const name = state.inputValues['name'] || '';
      const startingPage = state.inputValues['startingpage'] || '';
      if (!name || !startingPage) {
        setOpenChromeError('Please enter Name and Starting Page.');
        setOpenChromeLoading(false);
        return;
      }
      // Call the E-Procurement Fixed service (port 5023) to open Chrome
      const res = await fetch(`http://44.244.35.65:5023/api/open-chrome`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, starting_page: parseInt(startingPage) })
      });
      const data = await res.json();
      if (res.ok && data.session_id) {
        setIrepsSessionId(data.session_id);
        setChromeOpened(true);
        setState(prev => ({ ...prev, log: (prev.log || '') + `\n[INFO] Chrome opened. Session ID: ${data.session_id}\n` }));
      } else {
        setOpenChromeError(data.error || 'Failed to open Chrome.');
      }
    } catch (e) {
      setOpenChromeError('Failed to connect to backend.');
    } finally {
      setOpenChromeLoading(false);
    }
  };

  const handleStart = React.useCallback(async () => {
    const isGem = tool.name === 'gem';
    const isIreps = tool.name === 'IREPS';
    console.log('inputValues:', state.inputValues);
    console.log('selectedState:', state.selectedState);
    
    // Special handling for IREPS
    if (isIreps) {
      if (!chromeOpened) {
        // For IREPS, when Chrome hasn't been opened, only check name and startingpage
        const name = state.inputValues['name'] || '';
        const startingPage = state.inputValues['startingpage'] || '';
        if (!name.trim() || !startingPage.trim()) {
          const missingFields = [];
          if (!name.trim()) missingFields.push('name');
          if (!startingPage.trim()) missingFields.push('startingpage');
          const errorMsg = 'Please fill in all required fields.' + (missingFields.length ? '\nMissing: ' + missingFields.join(', ') : '');
          setState(prev => ({ ...prev, log: `\n[ERROR] ${errorMsg}\n` }));
          return;
        }
        // If Chrome hasn't been opened, call handleOpenChrome instead
        handleOpenChrome();
        return;
      } else {
        // For IREPS, when Chrome has been opened, check all required fields
        const missingFields: string[] = [];
        const requiredInputsFilled = Object.entries(state.inputValues).every(([key, val]) => {
          if (key === 'state_index' || key === 'city_input') return true;
          const inputDef = tool.inputs?.find(i => i.name === key);
          if (inputDef?.required && (val as string).trim() === '') {
            missingFields.push(key);
            return false;
          }
          return true;
        });
        if (!requiredInputsFilled) {
          const errorMsg = 'Please fill in all required fields.' + (missingFields.length ? '\nMissing: ' + missingFields.join(', ') : '');
          setState(prev => ({ ...prev, log: `\n[ERROR] ${errorMsg}\n` }));
          return;
        }
      }
    } else {
      // For non-IREPS tools, check all required fields as before
      const missingFields: string[] = [];
      const requiredInputsFilled = Object.entries(state.inputValues).every(([key, val]) => {
        // Ignore state_index and city_input for required check
        if (key === 'state_index' || key === 'city_input') return true;
        const inputDef = tool.inputs?.find(i => i.name === key);
        if (inputDef?.required && (val as string).trim() === '') {
          missingFields.push(key);
          return false;
        }
        return true;
      });
      if ((isGem && !state.selectedState) || !requiredInputsFilled) {
        if (isGem && !state.selectedState) missingFields.push('state');
        const errorMsg = 'Please fill in all required fields.' + (missingFields.length ? '\nMissing: ' + missingFields.join(', ') : '');
        setState(prev => ({ ...prev, log: `\n[ERROR] ${errorMsg}\n` }));
        return;
      }
    }
    setState(prev => ({ ...prev, isRunning: true }));
    setState(prev => ({ ...prev, log: '' }));
    setState(prev => ({ ...prev, outputFiles: [] }));
    setState(prev => ({ ...prev, isScrapingComplete: false }));
    const newRunId = Date.now().toString();
    setState(prev => ({ ...prev, runId: newRunId }));

    // Special handling for IREPS
    if (isIreps) {
      console.log('Starting IREPS scraping...');
      setState(prev => ({ ...prev, log: (prev.log || '') + '\n[INFO] Starting IREPS scraping...\n' }));
      
      try {
        const irepsPayload = {
          session_id: irepsSessionId,
          name: state.inputValues['name'],
          starting_page: parseInt(state.inputValues['startingpage'])
        };
        
        console.log('IREPS payload:', irepsPayload);
        
        const response = await fetch(`${API_CONFIG.SCRAPERS_API}/ireps/start-scraping`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(irepsPayload)
        });
        
        if (response.ok) {
          const data = await response.json();
          console.log('IREPS scraping started:', data);
          setState(prev => ({ ...prev, log: (prev.log || '') + '\n[INFO] IREPS scraping started successfully!\n' }));
          
          // Set up polling for output files
          const pollInterval = setInterval(async () => {
            try {
              const filesResponse = await fetch(`${API_CONFIG.SCRAPERS_API}/ireps/files?session_id=${irepsSessionId}`);
              if (filesResponse.ok) {
                const filesData = await filesResponse.json();
                setState(prev => ({ ...prev, outputFiles: filesData.files || [] }));
              }
            } catch (error) {
              console.error('Error polling for files:', error);
            }
          }, 2000);
          
          // Store the interval reference
          setState(prev => ({ ...prev, pollInterval }));
          
        } else {
          const errorData = await response.json();
          console.error('IREPS scraping failed:', errorData);
          setState(prev => ({ 
            ...prev, 
            log: (prev.log || '') + `\n[ERROR] IREPS scraping failed: ${errorData.error || 'Unknown error'}\n`,
            isRunning: false 
          }));
        }
      } catch (error) {
        console.error('Error starting IREPS scraping:', error);
        setState(prev => ({ 
          ...prev, 
          log: (prev.log || '') + `\n[ERROR] Failed to start IREPS scraping: ${error}\n`,
          isRunning: false 
        }));
      }
      return;
    }

    // For non-IREPS tools, use WebSocket communication
    const payload = {
      startingpage: state.inputValues['startingpage'],
      totalpages: state.inputValues['totalpages'],
      username: state.inputValues['username'],
      state_index: isGem && tool.valid_states ? tool.valid_states.indexOf(state.selectedState) + 1 : undefined,
      city_input: state.selectedCity || "",
      days_interval: state.inputValues['days_interval'],
      run_id: newRunId
    };
    
    // Create separate WebSocket connection for this state
    console.log(`Connecting to WebSocket server for state: ${state.selectedState}...`);
    const sock = io(getWsUrl('scraper'));
    
    // Add connection event handlers for debugging
    sock.on('connect', () => {
      console.log(`✅ WebSocket connected successfully for state: ${state.selectedState}`);
      setState(prev => ({ ...prev, log: (prev.log || '') + `\n[INFO] WebSocket connected successfully for ${state.selectedState}\n` }));
    });
    
    sock.on('connect_error', (error: any) => {
      console.error(`❌ WebSocket connection failed for state ${state.selectedState}:`, error);
      setState(prev => ({ ...prev, log: (prev.log || '') + `\n[ERROR] WebSocket connection failed for ${state.selectedState}: ${error.message}\n` }));
      setState(prev => ({ ...prev, isRunning: false }));
    });
    
    // Store socket for this specific state
    if (isGem && setGemState) {
      setGemState(prev => ({ 
        ...prev, 
        sockets: { 
          ...prev.sockets, 
          [state.selectedState]: sock 
        } 
      }));
    } else {
      setState(prev => ({ 
        ...prev, 
        sockets: { 
          ...prev.sockets, 
          [state.selectedState]: sock 
        } 
      }));
    }
    
    // Wait for connection before emitting
    if (sock.connected) {
      console.log(`Socket already connected for ${state.selectedState}, emitting start_scraping...`);
      sock.emit('start_scraping', payload);
    } else {
      sock.on('connect', () => {
        console.log(`Socket connected for ${state.selectedState}, now emitting start_scraping...`);
        sock.emit('start_scraping', payload);
      });
    }
    
    // Add a timeout to check if connection fails
    setTimeout(() => {
      if (!sock.connected) {
        console.error(`❌ WebSocket connection timeout for ${state.selectedState}`);
        setState(prev => ({ ...prev, log: (prev.log || '') + `\n[ERROR] WebSocket connection timeout for ${state.selectedState}\n` }));
        setState(prev => ({ ...prev, isRunning: false }));
      }
    }, 5000);
    setActiveJobState(state.selectedState);
    if (isGem && setGemState) {
      setGemState(prev => ({
        ...prev,
        activeJobState: state.selectedState,
        jobData: {
          ...prev.jobData,
          [state.selectedState]: {
            inputValues: { ...state.inputValues },
            selectedCity: state.selectedCity,
            log: '',
            isRunning: true,
            isScrapingComplete: false,
            runId: newRunId,
            outputFiles: [],
            stopMessage: ''
          }
        }
      }));
    } else {
    setJobData(prev => ({
      ...prev,
      [state.selectedState]: {
        inputValues: { ...state.inputValues },
        selectedCity: state.selectedCity,
        log: '',
        isRunning: true,
        isScrapingComplete: false,
        runId: newRunId,
        outputFiles: [],
        stopMessage: ''
      }
    }));
    }
    // Note: WebSocket event handlers are set up globally in useEffect above
    // No need to duplicate them here
    sock.on('disconnect', () => {
      console.log(`WebSocket disconnected for state: ${state.selectedState}`);
      // Update job-specific state
      if (isGem && setGemState) {
        setGemState(prev => ({
          ...prev,
          jobData: {
            ...prev.jobData,
            [state.selectedState]: {
              ...prev.jobData[state.selectedState],
              isRunning: false
            }
          }
        }));
        // Only update global state if this is the active job
        if (activeJobState === state.selectedState) {
          setGemState(prev => ({ ...prev, isRunning: false }));
        }
      } else {
        setJobData(prev => ({
          ...prev,
          [state.selectedState]: {
            ...prev[state.selectedState],
            isRunning: false
          }
        }));
        // Only update global state if this is the active job
        if (activeJobState === state.selectedState) {
      setState(prev => ({ ...prev, isRunning: false }));
        }
      }
    });
    // Add or update job in scrapingJobs
    setScrapingJobsWrapper(jobs => {
      // If state already exists, set to in-progress
      if (jobs.some(job => job.state === state.selectedState)) {
        return jobs.map(job => job.state === state.selectedState ? { ...job, status: 'in-progress' } : job);
      }
      // Otherwise, add new job
      return [...jobs, { state: state.selectedState, status: 'in-progress' }];
    });
  }, [tool.name, tool.inputs, tool.valid_states, state.inputValues, state.selectedState, state.selectedCity, setState, setActiveJobState, setJobData, setScrapingJobs]);

  const handleStop = React.useCallback(async () => {
    setState(prev => ({ ...prev, isStopping: true }));
    setState(prev => ({ ...prev, stopMessage: 'Stop scraping...' }));
    
    // Special handling for IREPS
    if (tool.name === 'IREPS' && irepsSessionId) {
      try {
        const response = await fetch(`${API_CONFIG.SCRAPERS_API}/ireps/stop-session`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ session_id: irepsSessionId })
        });
        
        if (response.ok) {
          setState(prev => ({ ...prev, stopMessage: 'IREPS scraping stopped.' }));
        } else {
          setState(prev => ({ ...prev, stopMessage: 'Failed to stop IREPS scraping.' }));
        }
      } catch (error) {
        setState(prev => ({ ...prev, stopMessage: 'Failed to stop IREPS scraping.' }));
      }
      
      // Clear polling interval
      if (state.pollInterval) {
        clearInterval(state.pollInterval);
        setState(prev => ({ ...prev, pollInterval: undefined }));
      }
    } else {
      // For non-IREPS tools
      if (activeJobState) {
        const socketsToUse = isGem && gemState ? gemState.sockets : state.sockets;
        if (socketsToUse && socketsToUse[activeJobState]) {
          // Disconnect the specific socket for the active job
          socketsToUse[activeJobState].disconnect();
          
          if (isGem && setGemState) {
            setGemState(prev => ({ 
              ...prev, 
              sockets: {
                ...prev.sockets,
                [activeJobState]: null
              }
            }));
            
            // Update job-specific state
            setGemState(prev => ({
              ...prev,
              jobData: {
                ...prev.jobData,
                [activeJobState]: {
                  ...prev.jobData[activeJobState],
                  isRunning: false,
                  isScrapingComplete: true
                }
              }
            }));
          } else {
            setState(prev => ({ 
              ...prev, 
              sockets: {
                ...prev.sockets,
                [activeJobState]: null
              }
            }));
            
            // Update job-specific state
            setJobData(prev => ({
              ...prev,
              [activeJobState]: {
                ...prev[activeJobState],
                isRunning: false,
                isScrapingComplete: true
              }
            }));
          }
        }
      }
      // Send stop request to backend
      try {
        await fetch(`${getWsUrl('scraper')}/api/stop-scraping`, { method: 'POST' });
        setState(prev => ({ ...prev, stopMessage: 'Scraping stopped.' }));
      } catch (error) {
        setState(prev => ({ ...prev, stopMessage: 'Failed to stop scraping.' }));
      }
    }
    
    setState(prev => ({ ...prev, isRunning: false }));
    setState(prev => ({ ...prev, isScrapingComplete: true })); // Treat stop as completion to show files
    setState(prev => ({ ...prev, isStopping: false }));
  }, [state.socket, state.pollInterval, tool.name, irepsSessionId, setState]);

  const handleDeleteFile = React.useCallback(async (filename: string) => {
    if (!state.runId && !irepsSessionId) return;
    if (window.confirm(`Are you sure you want to delete ${filename}?`)) {
      try {
        let res;
        if (tool.name === 'IREPS' && irepsSessionId) {
          res = await fetch(`${API_CONFIG.SCRAPERS_API}/ireps/delete-file`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ session_id: irepsSessionId, filename })
          });
        } else {
          res = await fetch(`${API_CONFIG.FILE_MANAGER_API}/api/delete/${state.runId}/${filename}`, {
            method: 'DELETE',
          });
        }
        
        if (res.ok) {
          // Delete from the currently active state's jobData
          if (activeJobState) {
            setJobData(prev => ({
              ...prev,
              [activeJobState]: {
                ...prev[activeJobState],
                outputFiles: prev[activeJobState]?.outputFiles.filter((f: string) => f !== filename) || []
              }
            }));
          } else {
            // Fallback to global outputFiles
            setState(prev => ({ ...prev, outputFiles: state.outputFiles.filter((f: string) => f !== filename) }));
          }
          setState(prev => ({ ...prev, log: prev.log + `\n${getTimestamp()} File deleted: ${filename}\n` }));
        } else {
          alert('Failed to delete file.');
        }
      } catch (error) {
        alert('Error deleting file.');
      }
    }
  }, [state.runId, irepsSessionId, tool.name, activeJobState, setJobData, setState, state.outputFiles]);

  const getTimestamp = React.useCallback(() => {
    return `[${new Date().toLocaleTimeString()}]`;
  }, []);

  const handleMergeFiles = React.useCallback(async () => {
    const runId = activeJobState ? jobData[activeJobState]?.runId : state.runId;
    if (!runId) return;
    
    setState(prev => ({ ...prev, log: prev.log + `\n${getTimestamp()} Merging files for ${activeJobState || 'current run'}...\n` }));
    
    try {
      // Use different endpoints for IREPS vs other tools
      const isIreps = tool.name === 'IREPS';
      const endpoint = isIreps 
        ? `${API_CONFIG.SCRAPERS_API}/ireps/merge-download/${irepsSessionId}`
        : `${API_CONFIG.FILE_MANAGER_API}/api/merge-download/${runId}`;
      
      const res = await fetch(endpoint);
      if (res.ok) {
        const fileName = isIreps ? `merged_data_${irepsSessionId}.csv` : `merged_data_${runId}.csv`;
        setState(prev => ({ ...prev, log: prev.log + `\n${getTimestamp()} Files merged into: ${fileName}\n` }));
        
        // Refresh the file list immediately after merge completes
        if (isIreps) {
          const filesRes = await fetch(`${API_CONFIG.SCRAPERS_API}/ireps/files?session_id=${irepsSessionId}`);
          if (filesRes.ok) {
            const filesData = await filesRes.json();
            setState(prev => ({ ...prev, outputFiles: filesData.files || [] }));
          }
        } else {
          const filesRes = await fetch(`${API_CONFIG.FILE_MANAGER_API}/api/files/${runId}`);
          if (filesRes.ok) {
            const files = await filesRes.json();
            // Update files in the currently active state's jobData
            if (activeJobState) {
              setJobData(prev => ({
                ...prev,
                [activeJobState]: {
                  ...prev[activeJobState],
                  outputFiles: files
                }
              }));
            } else {
              setState(prev => ({ ...prev, outputFiles: files }));
            }
          }
        }
        
        // Trigger the download
        const blob = await res.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = fileName;
        document.body.appendChild(a);
        a.click();
        a.remove();
        window.URL.revokeObjectURL(url);
      } else {
        const errorText = await res.text();
        setState(prev => ({ ...prev, log: prev.log + `\n${getTimestamp()} Failed to merge files: ${errorText}\n` }));
      }
    } catch (error) {
      setState(prev => ({ ...prev, log: prev.log + `\n${getTimestamp()} Error merging files: ${error}\n` }));
    }
  }, [activeJobState, jobData, state.runId, setState, getTimestamp, setJobData, tool.name, irepsSessionId]);

  // Use activeJobState for log, output, etc. - memoized for performance
  const currentJob = React.useMemo(() => {
    const job = activeJobState && typeof jobData[activeJobState] === 'object' ? jobData[activeJobState] : undefined;
    console.log('🔍 Current job state:', { activeJobState, job, globalState: state });
    return job;
  }, [activeJobState, jobData, state]);

  // Custom handler for E-Procurement
  // Remove two-step logic and always enable captcha input
  const [sessionId, setSessionId] = useState<string | null>(null);

  // E-Procurement WebSocket setup
  useEffect(() => {
    if (tool.name === 'eprocurement') {
      const socket = io(BACKEND_URL, {
        transports: ['websocket', 'polling'],
        timeout: 20000,
        forceNew: true,
        reconnection: true,
        reconnectionAttempts: 5,
        reconnectionDelay: 1000
      });

      const handleConnect = () => console.log('Connected to E-Procurement backend');
      const handleScrapingComplete = (data: { success: boolean; message: string; session_id: string }) => {
        setEIsRunning(false);
        setESuccess(data.message);
        if (data.session_id) {
          fetchSessionFiles(data.session_id);
          // Update run status to completed
          updateRunStatus(data.session_id, 'completed');
          // Clear active run
          setActiveRunId(null);
          setECurrentSessionId(null);
          // Stop file polling
          stopFilePolling();
        }
      };
      const handleScrapingError = (data: { error: string }) => {
        setEIsRunning(false);
        setEError(data.error);
        // Update run status to error if we have an active session
        if (eCurrentSessionId) {
          updateRunStatus(eCurrentSessionId, 'error');
          // Clear active run
          setActiveRunId(null);
          setECurrentSessionId(null);
          // Stop file polling
          stopFilePolling();
        }
      };
      const handleStatusUpdate = (data: { active: boolean; session_id: string | null }) => {
        setEIsRunning(data.active);
        if (data.session_id) {
          setECurrentSessionId(data.session_id);
          // Start polling for files when scraping starts
          if (data.active) {
            startFilePolling(data.session_id);
          } else {
            stopFilePolling();
          }
        }
      };

      const handleFileWritten = (data: { filename: string; session_id: string }) => {
        console.log('📄 File written:', data);
        if (data.session_id === eCurrentSessionId) {
          // Immediately fetch updated file list
          fetchSessionFiles(data.session_id);
        }
      };

      const handleScrapingOutput = (data: { output: string }) => {
        console.log('📝 Scraping output:', data.output);
        // You can add this to logs if needed
      };

      socket.on('connect', handleConnect);
      socket.on('scraping_complete', handleScrapingComplete);
      socket.on('scraping_error', handleScrapingError);
      socket.on('status_update', handleStatusUpdate);
      socket.on('file_written', handleFileWritten);
      socket.on('scraping_output', handleScrapingOutput);

      setESocket(socket);

      return () => {
        socket.off('connect', handleConnect);
        socket.off('scraping_complete', handleScrapingComplete);
        socket.off('scraping_error', handleScrapingError);
        socket.off('status_update', handleStatusUpdate);
        socket.off('file_written', handleFileWritten);
        socket.off('scraping_output', handleScrapingOutput);
        socket.disconnect();
        stopFilePolling();
      };
    }
  }, [tool.name]);

  // IREPS WebSocket setup for live logs
  useEffect(() => {
    if (tool.name === 'IREPS') {
      const ws = new WebSocket(getWsUrl('scrapersLog'));
      
      ws.onopen = () => {
        console.log('✅ Connected to IREPS WebSocket for live logs');
        setState(prev => ({ ...prev, log: (prev.log || '') + '\n[INFO] Connected to live logs\n' }));
        
        // Send a test message to verify connection
        setTimeout(() => {
          if (ws.readyState === WebSocket.OPEN) {
            console.log('🧪 Sending test message to WebSocket');
            ws.send(JSON.stringify({ type: 'test', message: 'Frontend test message' }));
          }
        }, 1000);
      };
      
      ws.onmessage = (event) => {
        try {
          console.log('📨 Received WebSocket message:', event.data);
          const data = JSON.parse(event.data);
          if (data.message) {
            console.log('📝 Adding log message:', data.message);
            setState(prev => ({ 
              ...prev, 
              log: (prev.log || '') + `\n${data.message}\n` 
            }));
          }
        } catch (error) {
          console.error('Error parsing WebSocket message:', error);
        }
      };
      
      ws.onerror = (error) => {
        console.error('❌ IREPS WebSocket error:', error);
        setState(prev => ({ 
          ...prev, 
          log: (prev.log || '') + '\n[ERROR] WebSocket connection error\n' 
        }));
      };
      
      ws.onclose = () => {
        console.log('🔌 IREPS WebSocket disconnected');
        setState(prev => ({ 
          ...prev, 
          log: (prev.log || '') + '\n[INFO] WebSocket disconnected\n' 
        }));
      };

      return () => {
        ws.close();
      };
    }
  }, [tool.name, setState]);

  // File polling for real-time updates
  const [filePollingInterval, setFilePollingInterval] = useState<NodeJS.Timeout | null>(null);

  const startFilePolling = (sessionId: string) => {
    console.log('🔄 Starting file polling for session:', sessionId);
    // Clear any existing interval
    if (filePollingInterval) {
      clearInterval(filePollingInterval);
    }
    
    // Start polling every 2 seconds for more responsive updates
    const interval = setInterval(() => {
      if (eIsRunning && eCurrentSessionId === sessionId) {
        console.log('🔄 Polling for new files...');
        fetchSessionFiles(sessionId);
      }
    }, 2000);
    
    setFilePollingInterval(interval);
  };

  const stopFilePolling = () => {
    console.log('🛑 Stopping file polling');
    if (filePollingInterval) {
      clearInterval(filePollingInterval);
      setFilePollingInterval(null);
    }
  };

  // Fetch session files
  const fetchSessionFiles = async (sessionId: string) => {
    try {
      console.log('🔍 Fetching files for session:', sessionId);
      const response = await fetch(`${BACKEND_URL}/api/files/${sessionId}`);
      console.log('📊 Files response status:', response.status);
      
      if (response.ok) {
        const data = await response.json();
        console.log('📁 Files data:', data);
        const fileNames = data.files.map((f: any) => getFileNameOnly(f.name || f));
        console.log('📄 File names:', fileNames);
        setEOutputFiles(fileNames);
        
        // Update the run's output files
        setEProcRuns(prev => prev.map(run => {
          if (run.sessionId === sessionId) {
            return { ...run, outputFiles: fileNames };
          }
          return run;
        }));
      } else {
        console.error('❌ Failed to fetch files, status:', response.status);
      }
    } catch (error) {
      console.error('❌ Failed to fetch session files:', error);
    }
  };

  // E-Procurement handlers (Chrome)
  const handleOpenEdge = async () => {
    setEError('');
    setESuccess('');
    setEdgeOpened(false);
    
    if (!eBaseUrl) {
      setEError('Please enter the E-Procurement URL.');
      return;
    }

    setEIsRunning(true);
    try {
      console.log('[DEBUG] Sending URL to backend:', eBaseUrl);
      console.log('[DEBUG] Backend URL:', `${BACKEND_URL}/api/open-chrome`);
      
      const res = await fetch(`${BACKEND_URL}/api/open-chrome`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ url: eBaseUrl })
      });
      
    const data = await res.json();
      console.log('[DEBUG] Backend response:', data);
      
      if (res.ok) {
        setEdgeOpened(true);
        setECurrentSessionId(data.session_id);
        setESuccess(`[INFO] Chrome opened successfully with URL: ${data.url}\n[INFO] Please enter the captcha in the Chrome window, then fill the rest of the fields and click Start Scraping.`);
      } else {
        setEError(data.error || 'Failed to open Chrome');
      }
    } catch (error) {
      console.error('[DEBUG] Error:', error);
      setEError('Failed to connect to backend server');
    } finally {
    setEIsRunning(false);
    }
  };

  const handleStartEproc = async () => {
    if (!eBaseUrl || !eTenderType || !eDaysInterval || !eStartPage || !eCaptcha) {
      setEError('Please fill in all required fields.');
      return;
    }

    // Check if Edge is opened and session exists
    if (!eCurrentSessionId) {
      setEError('Session not found. Please open Edge first.');
      return;
    }

    // If there's an active run, stop it first
    if (activeRunId && eIsRunning) {
      try {
        await handleStopEproc();
        // Wait a moment for the stop to complete
        await new Promise(resolve => setTimeout(resolve, 1000));
      } catch (error) {
        console.error('Failed to stop previous run:', error);
      }
    }

    // Create new run entry using the existing session ID
    const runId = `eproc-run-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    
    const newRun: EProcRun = {
      id: runId,
      sessionId: eCurrentSessionId, // Use the existing session ID from Open Chrome
      baseUrl: eBaseUrl,
      tenderType: eTenderType,
      daysInterval: eDaysInterval,
      startPage: eStartPage,
      captcha: eCaptcha,
      status: 'running',
      startTime: new Date(),
      outputFiles: [],
      isActive: true
    };

    // Add new run to the list
    setEProcRuns(prev => [...prev, newRun]);
    setActiveRunId(runId);
    setEIsRunning(true);
    setEScrapingStarted(true);
    setEError('');
    setESuccess('');

    try {
      const res = await fetch(`${BACKEND_URL}/api/start-eproc-scraping`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          session_id: eCurrentSessionId, // Use the existing session ID
          base_url: eBaseUrl,
          tender_type: eTenderType,
          days_interval: parseInt(eDaysInterval),
          start_page: parseInt(eStartPage),
          captcha: eCaptcha
        })
      });

      const data = await res.json();

      if (res.ok) {
        setESuccess('Scraping started successfully!');
        // Start file polling immediately when scraping starts
        if (eCurrentSessionId) {
          startFilePolling(eCurrentSessionId);
          // Also do an immediate check for any existing files
          setTimeout(() => {
            fetchSessionFiles(eCurrentSessionId);
          }, 1000);
        }
      } else {
        setEError(data.error || 'Failed to start scraping');
        setEIsRunning(false);
        // Update run status to error
        setEProcRuns(prev => prev.map(run => 
          run.id === runId ? { ...run, status: 'error', isActive: false } : run
        ));
      }
    } catch (error) {
      setEError('Failed to connect to backend server');
      setEIsRunning(false);
      // Update run status to error
      setEProcRuns(prev => prev.map(run => 
        run.id === runId ? { ...run, status: 'error', isActive: false } : run
      ));
    }
  };

  const handleStopEproc = async () => {
    if (!activeRunId || !eCurrentSessionId) {
      setEError('No active run to stop.');
      return;
    }

    try {
      const res = await fetch(`${BACKEND_URL}/api/stop-scraping`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          session_id: eCurrentSessionId
        })
      });

      if (res.ok) {
        setESuccess('Scraping stopped by user');
        setEIsRunning(false);
        setEScrapingStarted(false);
        setEdgeOpened(false);
        
        // Update run status to stopped
        setEProcRuns(prev => prev.map(run => 
          run.id === activeRunId ? { 
            ...run, 
            status: 'stopped', 
            isActive: false,
            endTime: new Date()
          } : run
        ));
        
        setActiveRunId(null);
        setECurrentSessionId(null);
        
        // Stop file polling
        stopFilePolling();
      } else {
        setEError('Failed to stop scraping');
      }
    } catch (error) {
      console.error('Failed to stop scraping:', error);
      setEError('Failed to stop scraping');
    }
  };

  const handleResetEproc = () => {
    setEBaseUrl('');
    setETenderType('');
    setEDaysInterval('');
    setEStartPage('');
    setECaptcha('');
    setEIsRunning(false);
    setEScrapingStarted(false);
    setEError('');
    setESuccess('');
    setEdgeOpened(false);
    setEOutputFiles([]);
    setECurrentSessionId(null);
    setActiveRunId(null);
    // Stop any file polling
    stopFilePolling();
    // Don't clear the runs list - keep history
  };

  // Function to switch to a different run
  const switchToRun = (runId: string) => {
    const run = eProcRuns.find(r => r.id === runId);
    if (run) {
      setEBaseUrl(run.baseUrl);
      setETenderType(run.tenderType);
      setEDaysInterval(run.daysInterval);
      setEStartPage(run.startPage);
      setECaptcha(run.captcha);
      setECurrentSessionId(run.sessionId);
      setEOutputFiles(run.outputFiles);
      setActiveRunId(runId);
      setEIsRunning(run.isActive);
      setEScrapingStarted(run.isActive);
      
      // Clear any error/success messages when switching runs
      setEError('');
      setESuccess('');
      
      // If switching to a completed run, fetch its files
      if (run.status === 'completed' && run.sessionId) {
        fetchSessionFiles(run.sessionId);
      }
    }
  };

  // Function to clear completed runs
  const clearCompletedRuns = () => {
    setEProcRuns(prev => prev.filter(run => run.status === 'running'));
    // If the active run was cleared, reset the form
    if (activeRunId && !eProcRuns.find(r => r.id === activeRunId)) {
      setActiveRunId(null);
      setECurrentSessionId(null);
      setEOutputFiles([]);
    }
  };

  // Function to update run status when scraping completes
  const updateRunStatus = (sessionId: string, status: 'completed' | 'stopped' | 'error', outputFiles?: string[]) => {
    setEProcRuns(prev => prev.map(run => {
      if (run.sessionId === sessionId) {
        return {
          ...run,
          status,
          isActive: false,
          endTime: new Date(),
          outputFiles: outputFiles || run.outputFiles
        };
      }
      return run;
    }));
  };

  // File management handlers
  const handleEprocDownload = async (filename: string) => {
    if (!eCurrentSessionId) return;
    const safeFilename = getFileNameOnly(filename);
    try {
      const response = await fetch(`${BACKEND_URL}/api/download/${eCurrentSessionId}/${safeFilename}`);
      if (response.ok) {
        const blob = await response.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = safeFilename;
        document.body.appendChild(a);
        a.click();
        a.remove();
        window.URL.revokeObjectURL(url);
      }
    } catch (error) {
      setEError('Failed to download file');
    }
  };

  const handleEprocMerge = async () => {
    if (!eCurrentSessionId) return;

    try {
      setESuccess('Processing merge request...');
      
      // First, make a request to check the response headers
      const response = await fetch(`${BACKEND_URL}/api/merge-download/${eCurrentSessionId}`);
      
      if (response.ok) {
        // Get database status from headers
        const dbStatus = response.headers.get('X-DB-Status');
        const dbRecords = response.headers.get('X-DB-Records-Inserted');
        const dbError = response.headers.get('X-DB-Error');
        
        // Download the file
        const blob = await response.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `merged_data_${eCurrentSessionId}.csv`;
        document.body.appendChild(a);
        a.click();
        a.remove();
        window.URL.revokeObjectURL(url);
        
        // Show appropriate success message
        if (dbStatus === 'success') {
          setESuccess(`✅ Files merged and downloaded successfully! Database: ${dbRecords} records stored.`);
        } else {
          setESuccess(`✅ Files merged and downloaded successfully! ⚠️ Database storage failed: ${dbError || 'Database not accessible'}`);
        }
        
        // Refresh file list
        fetchSessionFiles(eCurrentSessionId);
      } else {
        const errorData = await response.json();
        setEError(`Failed to merge files: ${errorData.error || 'Unknown error'}`);
      }
    } catch (error) {
      setEError('Failed to merge and download files');
    }
  };

  const handleEprocGlobalMerge = async () => {
    if (!eCurrentSessionId || eOutputFiles.length === 0) return;

    try {
      // Create a global merge session
      const globalSessionId = `global-merge-${Date.now()}`;
      
      // Prepare files data for global merge
      const files = eOutputFiles.map(filename => ({
        session_id: eCurrentSessionId,
        filename: filename
      }));

      // Call global merge endpoint
      const response = await fetch(`${BACKEND_URL}/api/merge-global`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          session_id: globalSessionId,
          files: files
        })
      });

      if (response.ok) {
        const result = await response.json();
        
        // Download the merged file
        window.open(`${BACKEND_URL}/api/download-global-merge/${globalSessionId}`, '_blank');
        
        // Show appropriate success message based on database status
        if (result.database_status === 'success') {
          setESuccess(`✅ Global merge completed! ${result.total_files} files merged, ${result.database_records} records stored in database.`);
        } else {
          setESuccess(`✅ Global merge completed! ${result.total_files} files merged. ⚠️ Database storage failed: ${result.database_error || 'Database not accessible'}`);
        }
      } else {
        const errorData = await response.json();
        setEError(`Failed to merge files globally: ${errorData.error || 'Unknown error'}`);
      }
    } catch (error) {
      setEError('Failed to merge files globally');
    }
  };

  const handleEprocDeleteFile = async (filename: string) => {
    if (!eCurrentSessionId) return;

    try {
      const response = await fetch(`${BACKEND_URL}/api/delete-file/${eCurrentSessionId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ filename })
      });

      if (response.ok) {
        setESuccess(`File ${filename} deleted successfully!`);
        // Refresh file list
        fetchSessionFiles(eCurrentSessionId);
      } else {
        setEError('Failed to delete file');
      }
    } catch (error) {
      setEError('Failed to delete file');
    }
  };

  // Handler to open Edge for captcha
  // Remove handleOpenEdge and edgeOpened logic for E-Procurement

  // Update handleSubmitCaptcha to include session_id
  const handleSubmitCaptcha = async () => {
    setEIsRunning(true);
    if (!eCurrentSessionId) {
      setEError('Session ID missing. Please restart.');
      setEIsRunning(false);
      return;
    }
    const res = await fetch(`${BACKEND_URL}/api/submit-eproc-captcha`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ captcha: eCaptcha, session_id: eCurrentSessionId })
    });
    const data = await res.json();
    if (data.status === 'success') {
      setESuccess('Scraping completed!');
      setEIsRunning(false);
      setEStep('start');
      setECurrentSessionId(null);
    } else {
      setEError(data.message || 'Scraping failed');
      setEIsRunning(false);
    }
  };

  const handleKMergeFiles = async () => {
    if (!state.runId) return;
    setState(prev => ({ ...prev, log: prev.log + `\n${getTimestamp()} K-Merging Karnataka files...\n` }));
    try {
      const res = await fetch(`${API_CONFIG.SCRAPERS_API}/ireps/kmerge-files`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ session_id: state.runId })
      });
      if (res.ok) {
        setState(prev => ({ ...prev, log: prev.log + `\n${getTimestamp()} Karnataka files merged into: karnataka_merged_${state.runId}.xlsx\n` }));
        const filesRes = await fetch(`${API_CONFIG.FILE_MANAGER_API}/api/files/${state.runId}`);
        if (filesRes.ok) {
          const files = await filesRes.json();
          setState(prev => ({ ...prev, outputFiles: files }));
        }
        // Optionally, trigger the download in a new tab
        const blob = await res.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `karnataka_merged_${state.runId}.xlsx`;
        document.body.appendChild(a);
        a.click();
        a.remove();
        window.URL.revokeObjectURL(url);
      } else {
        setState(prev => ({ ...prev, log: prev.log + `\n${getTimestamp()} Failed to K-merge Karnataka files.\n` }));
      }
    } catch (error) {
      setState(prev => ({ ...prev, log: prev.log + `\n${getTimestamp()} Error K-merging Karnataka files.\n` }));
    }
  };



  // Test function to manually trigger state updates
  const testWebSocketConnection = React.useCallback(() => {
    console.log('🧪 Testing WebSocket connection...');
    
    // Test 1: Check if socket exists
    if (!state.socket) {
      console.log('❌ No socket found');
      return;
    }
    
    // Test 2: Check socket connection status
    console.log('🔌 Socket connected:', state.socket.connected);
    
    // Test 3: Manually trigger a test log update
    setState((prev: any) => ({
      ...prev,
      log: (prev.log || '') + '\n🧪 TEST: Manual log update at ' + new Date().toLocaleTimeString() + '\n'
    }));
    
    // Test 4: Manually trigger a test file update
    setState((prev: any) => ({
      ...prev,
      outputFiles: [...(prev.outputFiles || []), 'test_file_' + Date.now() + '.xlsx']
    }));
    
    console.log('✅ Test completed - check if logs and files appear');
  }, [state.socket, setState]);

  // Cleanup effect for IREPS polling interval
  useEffect(() => {
    return () => {
      if (state.pollInterval) {
        clearInterval(state.pollInterval);
      }
    };
  }, [state.pollInterval]);

  if (tool.name === 'eprocurement') {
    const isAllFieldsFilled = eBaseUrl && eTenderType && eDaysInterval && eCaptcha && eStartPage && !eIsRunning;
    
    return (
      <div className="space-y-6 bg-transparent dark:bg-gray-900 p-4 rounded-xl">
        <button
          className="text-sm text-blue-400 hover:underline flex items-center gap-2"
          onClick={onBack}
        >
          <ArrowLeft size={16} /> Back
        </button>
        
        <h2 className="text-2xl font-bold text-gray-900 dark:text-white">E-Procurement Scraper</h2>
        <p className="text-gray-700 dark:text-gray-400 mb-4">
          Scrapes data from the E-Procurement website and generates Excel files for each page.
        </p>

        {/* Multiple Runs Status Display */}
        {eProcRuns.length > 0 && (
          <div className="bg-gray-800/50 border border-gray-600 rounded-lg p-4">
            <div className="flex items-center justify-between mb-3">
              <h4 className="text-white font-semibold">📊 Run History</h4>
              <button
                onClick={clearCompletedRuns}
                className="text-xs bg-gray-600 hover:bg-gray-700 text-white px-2 py-1 rounded"
              >
                Clear Completed
              </button>
            </div>
            <div className="flex flex-wrap gap-2">
              {eProcRuns.map((run) => (
                <button
                  key={run.id}
                  onClick={() => switchToRun(run.id)}
                  className={`px-3 py-1 rounded text-white font-semibold cursor-pointer transition-colors ${
                    run.status === 'running' ? 'bg-blue-500 hover:bg-blue-600' :
                    run.status === 'completed' ? 'bg-green-500 hover:bg-green-600' :
                    run.status === 'stopped' ? 'bg-yellow-500 hover:bg-yellow-600' :
                    'bg-red-500 hover:bg-red-600'
                  } ${activeRunId === run.id ? 'ring-2 ring-violet-400' : ''}`}
                  title={`${run.baseUrl} - ${run.tenderType} - ${run.daysInterval} days - Page ${run.startPage}`}
                >
                  {run.status === 'running' && '🔄'}
                  {run.status === 'completed' && '✅'}
                  {run.status === 'stopped' && '⏹️'}
                  {run.status === 'error' && '❌'}
                  {' '}
                  {run.baseUrl.split('/')[2]?.split('.')[0] || 'Run'} 
                  ({run.startTime.toLocaleTimeString()})
                  {run.outputFiles.length > 0 && (
                    <span className="ml-1 text-xs">📄{run.outputFiles.length}</span>
                  )}
                </button>
              ))}
            </div>
          </div>
        )}

        <div className="space-y-4">
          {/* URL Input */}
          <div>
            <label className="block text-sm font-medium mb-2">
              Enter E-Procurement URL <span className="text-red-400">*</span>
            </label>
            <div className="flex gap-4">
              <input 
                type="text" 
                className="w-full bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg px-3 py-2 text-gray-900 dark:text-white" 
                value={eBaseUrl} 
                onChange={e => setEBaseUrl(e.target.value)} 
                disabled={eIsRunning} 
                placeholder="https://etenders.hry.nic.in/nicgep/app"
              />
              <button
                className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded flex items-center gap-2 disabled:opacity-50"
                onClick={handleOpenEdge}
                disabled={!eBaseUrl || eIsRunning}
                type="button"
              >
                Open Chrome
              </button>
            </div>
            <p className="text-xs text-gray-400 mt-1">
              Examples: https://etenders.hry.nic.in/nicgep/app or https://mahatenders.gov.in/nicgep/app
            </p>
          </div>

          {/* Tender Type */}
          <div>
            <label className="block text-sm font-medium mb-2">
              Tender Type <span className="text-red-400">*</span>
            </label>
            <select
              className="w-full bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg px-3 py-2 text-gray-900 dark:text-white"
              value={eTenderType}
              onChange={e => setETenderType(e.target.value)}
              disabled={eIsRunning}
            >
              <option value="">Select tender type...</option>
              <option value="O">Open Tender (O)</option>
              <option value="L">Limited Tender (L)</option>
            </select>
          </div>

          {/* Days Interval */}
          <div>
            <label className="block text-sm font-medium mb-2">
              How many days back to scrape <span className="text-red-400">*</span>
            </label>
            <input 
              type="number" 
              className="w-full bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg px-3 py-2 text-gray-900 dark:text-white" 
              value={eDaysInterval} 
              onChange={e => setEDaysInterval(e.target.value)} 
              disabled={eIsRunning}
              min="1"
              max="365"
              placeholder="7"
            />
          </div>

          {/* Start Page */}
          <div>
            <label className="block text-sm font-medium mb-2">
              Starting Page Number <span className="text-red-400">*</span>
            </label>
            <input 
              type="number" 
              className="w-full bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg px-3 py-2 text-gray-900 dark:text-white" 
              value={eStartPage} 
              onChange={e => setEStartPage(e.target.value)} 
              disabled={eIsRunning}
              min="1"
              placeholder="1"
            />
          </div>

          {/* Captcha */}
          <div>
            <label className="block text-sm font-medium mb-2">
              Captcha <span className="text-red-400">*</span>
            </label>
            <input 
              type="text" 
              className="w-full bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg px-3 py-2 text-gray-900 dark:text-white" 
              value={eCaptcha} 
              onChange={e => setECaptcha(e.target.value)} 
              disabled={eIsRunning}
              placeholder="Enter captcha from the website"
            />
          </div>

          {/* Instructions */}
          <div className="bg-blue-900/20 border border-blue-500/30 rounded-lg p-4">
            <h4 className="text-blue-400 font-semibold mb-2">Instructions:</h4>
            <ol className="text-blue-300 text-sm space-y-1">
              <li>1. Enter the E-Procurement website URL</li>
              <li>2. Click "Open Chrome" to open the website in Chrome browser</li>
              <li>3. Fill in all the required fields above</li>
              <li>4. Enter the captcha from the website</li>
              <li>5. Click "Start Scraping" to begin the process</li>
            </ol>
            <div className="mt-3 p-2 bg-yellow-900/20 border border-yellow-500/30 rounded">
              <p className="text-yellow-300 text-xs">
                <strong>Note:</strong> If Edge opens the wrong URL, try refreshing the page (Ctrl+F5) to clear cache, 
                or check the browser console (F12) for debug information.
              </p>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex gap-4">
            <button
              className="bg-green-600 hover:bg-green-700 text-white px-6 py-2 rounded flex items-center gap-2 disabled:opacity-50"
              onClick={handleStartEproc}
              disabled={!isAllFieldsFilled || !edgeOpened || !eCurrentSessionId}
            >
              <Play size={16} /> Start Scraping
            </button>
            
            {eIsRunning && (
              <button
                className="bg-red-600 hover:bg-red-700 text-white px-6 py-2 rounded flex items-center gap-2"
                onClick={handleStopEproc}
              >
                <Square size={16} /> Stop Scraping
              </button>
            )}
            
            <button
              className="bg-gray-500 hover:bg-gray-600 text-white px-6 py-2 rounded flex items-center gap-2 disabled:opacity-50"
              onClick={handleResetEproc}
              disabled={eIsRunning}
            >
              Reset
            </button>
          </div>

          {/* Help message when Start Scraping is disabled */}
          {(!isAllFieldsFilled || !edgeOpened || !eCurrentSessionId) && (
            <div className="bg-yellow-900/20 border border-yellow-500/30 rounded-lg p-3">
              <div className="text-yellow-400 text-sm">
                {!edgeOpened || !eCurrentSessionId 
                  ? "⚠️ Please click 'Open Chrome' first to establish a browser session."
                  : !isAllFieldsFilled 
                    ? "⚠️ Please fill in all required fields before starting scraping."
                    : "⚠️ Please complete all required steps before starting scraping."
                }
              </div>
            </div>
          )}

          {/* Status Messages */}
          {eError && (
            <div className="bg-red-900/20 border border-red-500/30 rounded-lg p-3">
              <div className="text-red-400 font-semibold">Error: {eError}</div>
            </div>
          )}
          
          {eSuccess && (
            <div className="bg-green-900/20 border border-green-500/30 rounded-lg p-3">
              <div className="text-green-400 font-semibold">{eSuccess}</div>
            </div>
          )}

          {/* Log Output */}
          {eScrapingStarted && (
            <div className="bg-black border border-gray-600 rounded-lg p-4">
              <div className="flex items-center justify-between mb-2">
                <div className="text-gray-400 text-sm">Real-time Log:</div>
                <div className="text-green-400 text-xs">✅ Connected to Backend</div>
              </div>
              <LiveLogViewer />
            </div>
          )}

          {/* Output Files Section - Always Visible */}
          <div className="bg-gray-800/50 border border-gray-600 rounded-lg p-4">
            <div className="flex items-center justify-between mb-4">
              <h4 className="text-white font-semibold text-lg">
                📁 Output Files
                {eIsRunning && (
                  <span className="ml-2 text-green-400 text-sm font-normal">
                    🔄 Live Updates
                  </span>
                )}
                {activeRunId && (
                  <span className="ml-2 text-blue-400 text-sm font-normal">
                    | Run: {activeRunId.slice(-8)}
                  </span>
                )}
              </h4>
              <div className="flex gap-2">
                <button
                  onClick={() => {
                    if (eCurrentSessionId) {
                      fetchSessionFiles(eCurrentSessionId);
                    } else if (activeRunId) {
                      const run = eProcRuns.find(r => r.id === activeRunId);
                      if (run && run.sessionId) {
                        fetchSessionFiles(run.sessionId);
                      }
                    }
                  }}
                  className="bg-blue-600 hover:bg-blue-700 text-white px-3 py-1 rounded flex items-center gap-1 text-sm"
                >
                  🔄 Refresh
                </button>
                {eOutputFiles.length > 0 && (
                  <>
                    <button
                      onClick={handleEprocMerge}
                      className="bg-purple-600 hover:bg-purple-700 text-white px-3 py-1 rounded flex items-center gap-1 text-sm"
                      disabled={!eCurrentSessionId}
                    >
                      📊 Merge All Files
                    </button>
                    <button
                      onClick={handleEprocGlobalMerge}
                      className="bg-indigo-600 hover:bg-indigo-700 text-white px-3 py-1 rounded flex items-center gap-1 text-sm"
                      disabled={!eCurrentSessionId}
                    >
                      🌐 Global Merge & Store
                    </button>
                  </>
                )}
              </div>
            </div>
            
            {eOutputFiles.length > 0 ? (
              <div className="grid gap-2">
                {eOutputFiles.map((filename, index) => (
                  <div key={index} className="flex items-center justify-between bg-gray-700/50 rounded p-3">
                    <div className="flex items-center gap-3">
                      <FileText size={16} className="text-blue-400" />
                      <div>
                        <span className="text-white text-sm font-medium">{filename}</span>
                        <div className="text-gray-400 text-xs">
                          Session: {eCurrentSessionId?.slice(0, 8) || 'Unknown'}
                          {activeRunId && (
                            <span className="ml-2">
                              | Run: {activeRunId.slice(-8)}
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                    <div className="flex gap-2">
                      <button
                        onClick={() => handleEprocDownload(filename)}
                        className="bg-green-600 hover:bg-green-700 text-white p-2 rounded"
                        title="Download"
                      >
                        📥
                      </button>
                      <button
                        onClick={() => {
                          if (eCurrentSessionId) {
                            handleEprocDelete(filename);
                          }
                        }}
                        className="bg-red-600 hover:bg-red-700 text-white p-2 rounded"
                        title="Delete"
                      >
                        🗑️
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-center py-8">
                <div className="text-gray-500 mb-2">📄 No output files yet</div>
                <div className="text-sm text-gray-400">
                  {activeRunId 
                    ? 'Output files will appear here after scraping starts for this run.'
                    : 'Select a run from the history above or start a new scraping job.'
                  }
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 bg-transparent dark:bg-gray-900 p-4 rounded-xl">
      <button
        className="text-sm text-blue-400 hover:underline flex items-center gap-2"
        onClick={onBack}
      >
        <ArrowLeft size={16} /> Back
      </button>
      <h2 className="text-2xl font-bold text-gray-900 dark:text-white">{tool.name}</h2>
      <p className="text-gray-700 dark:text-gray-400 mb-4">{tool.description}</p>
      {/* Scraping Jobs Navigation Bar */}
      {getScrapingJobs() && getScrapingJobs().length > 0 && (
        <div className="flex gap-2 mb-4">
          {getScrapingJobs().map((job: any) => (
            <span
              key={job.state}
              onClick={() => {
                setActiveJobState(job.state);
                // Restore form fields for this job
                const jobInfo = isGem ? gemState?.jobData[job.state] : jobData[job.state];
                if (jobInfo) {
                  if (isGem && setGemState) {
                    setGemState((prev: any) => ({ ...prev, inputValues: { ...jobInfo.inputValues } }));
                    setGemState((prev: any) => ({ ...prev, selectedCity: jobInfo.selectedCity }));
                  } else {
                  setState((prev: any) => ({ ...prev, inputValues: { ...jobInfo.inputValues } }));
                  setState((prev: any) => ({ ...prev, selectedCity: jobInfo.selectedCity }));
                  }
                }
              }}
              className={`px-3 py-1 rounded text-white font-semibold cursor-pointer ${job.status === 'in-progress' ? 'bg-blue-500' : 'bg-green-500'} ${activeJobState === job.state ? 'ring-2 ring-violet-400' : ''}`}
            >
              {job.state}
            </span>
          ))}
        </div>
      )}
      <div className="space-y-4">
        {/* Special handling for gem tool (states/cities) */}
        {tool.name === 'gem' && (
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium mb-2 text-gray-900 dark:text-white">
                Select State/Region <span className="text-red-500">*</span>
              </label>
              <select
                value={state.selectedState || ''}
                onChange={e => {
                  const selectedState = e.target.value;
                  console.log('State selected:', selectedState);
                  setState((prev: any) => ({ 
                    ...prev, 
                    selectedState: selectedState,
                    selectedCity: '',
                    isRunning: false,
                    isScrapingComplete: false,
                    log: '',
                    runId: null,
                    outputFiles: [],
                    stopMessage: ''
                  }));
                  
                  // Update input values with state index
                  if (selectedState && tool.valid_states) {
                    const stateIndex = tool.valid_states.indexOf(selectedState) + 1;
                    setState((prev: any) => ({
                      ...prev,
                      inputValues: {
                        ...prev.inputValues,
                        state_index: String(stateIndex)
                      }
                    }));
                  }
                }}
                className="w-full bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg px-3 py-2 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="">Choose a state...</option>
                {tool.valid_states && tool.valid_states.map((stateName: string) => (
                  <option key={stateName} value={stateName}>{stateName}</option>
                ))}
              </select>
            </div>
            
            {state.selectedState && tool.valid_cities?.[state.selectedState] && (
              <div>
                <label className="block text-sm font-medium mb-2 text-gray-900 dark:text-white">
                  Select City (optional)
                </label>
                <select
                  value={state.selectedCity || ''}
                  onChange={e => {
                    const selectedCity = e.target.value;
                    console.log('City selected:', selectedCity);
                    setState((prev: any) => ({ 
                      ...prev, 
                      selectedCity: selectedCity 
                    }));
                    
                    // Update input values with city
                    setState((prev: any) => ({
                      ...prev,
                      inputValues: {
                        ...prev.inputValues,
                        city_input: selectedCity || ""
                      }
                    }));
                  }}
                  className="w-full bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg px-3 py-2 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="">Skip city filtering</option>
                  {tool.valid_cities[state.selectedState].map((city: string) => (
                    <option key={city} value={city}>{city}</option>
                  ))}
                </select>
              </div>
            )}
          </div>
        )}
        {/* Render input fields for all tools with inputs */}
        {tool.inputs && tool.inputs.length > 0 ? (
          <div className="space-y-4">
            {tool.inputs.map((input: any) => {
              // For IREPS, only show name and startingpage fields initially
              if (tool.name === 'IREPS' && !chromeOpened) {
                if (input.name !== 'name' && input.name !== 'startingpage') {
                  return null;
                }
              }
              
              // Skip city_input and state_index for all tools
              if (input.name === 'city_input' || input.name === 'state_index') {
                return null;
              }
              
              return (
                <div key={input.name}>
                  <label className="block text-sm font-medium mb-2 text-gray-900 dark:text-white">
                    {input.description || input.name}
                    {input.required && <span className="text-red-500 ml-1">*</span>}
                  </label>
                  <input
                    type={input.type === 'int' ? 'number' : 'text'}
                    value={state.inputValues?.[input.name] || input.default || ''}
                    onChange={e => handleInputChange(input.name, (e.target as HTMLInputElement).value)}
                    placeholder={input.description || `Enter ${input.name}`}
                    className="w-full bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg px-3 py-2 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    required={input.required}
                  />
                  {input.default && input.default !== '' && (
                    <p className="text-xs text-gray-500 mt-1">Default: {input.default}</p>
                  )}
                </div>
              );
            })}
          </div>
        ) : (
          <div className="text-gray-500 dark:text-gray-400 text-center py-4">
            No input fields required for this tool.
          </div>
        )}
        {tool.name === 'IREPS' && (
          <div className="mb-4">
            <div className="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-3 mb-3">
              <p className="text-sm text-blue-800 dark:text-blue-200">
                <strong>IREPS Workflow:</strong> Enter Name and Starting Page → Click "Open Chrome" button → Fill remaining fields → Click "Continue"
              </p>
            </div>
            {openChromeError && <div className="text-red-400 mt-2">{openChromeError}</div>}
            {chromeOpened && (
              <div className="text-green-400 mt-2">
                Chrome opened successfully! Fill the remaining fields and click "Continue" to start scraping.
              </div>
            )}
          </div>
        )}
        {/* Action Buttons */}
        <div className="flex flex-wrap gap-3 mt-6">
          <button
            className="bg-green-600 hover:bg-green-700 text-white px-6 py-3 rounded-lg flex items-center justify-center gap-2 font-semibold transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            onClick={async () => {
              try {
                await handleStart();
              } catch (error) {
                console.error('Error in handleStart:', error);
                setState(prev => ({ 
                  ...prev, 
                  log: (prev.log || '') + `\n[ERROR] Failed to start: ${error}\n`,
                  isRunning: false 
                }));
              }
            }}
            disabled={state.isRunning}
          >
            <Play size={18} /> {tool.name === 'IREPS' && !chromeOpened ? 'Open Chrome' : (chromeOpened ? 'Continue' : 'Start Scraping')}
          </button>
          <button
            className="bg-red-600 hover:bg-red-700 text-white px-6 py-3 rounded-lg flex items-center justify-center gap-2 font-semibold transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            onClick={handleStop}
            disabled={!state.isRunning || state.isStopping}
          >
            <Square size={18} /> Stop Scraping
          </button>
        </div>
        {/* Live Logs Section */}
        <div className="mt-6">
          <div className="flex items-center justify-between mb-2">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
              Live Logs {state.isRunning && <span className="text-green-500 animate-pulse">●</span>}
            </h3>
            <div className="flex gap-2">
              <button
                onClick={() => setState((prev: any) => ({ ...prev, log: '' }))}
                className="text-xs bg-gray-600 hover:bg-gray-700 text-white px-2 py-1 rounded"
              >
                Clear
              </button>
              <button
                onClick={() => {
                  const logElement = document.getElementById('log-container');
                  if (logElement) logElement.scrollTop = logElement.scrollHeight;
                }}
                className="text-xs bg-blue-600 hover:bg-blue-700 text-white px-2 py-1 rounded"
              >
                Scroll to Bottom
              </button>
            </div>
          </div>
          <div 
            id="log-container"
            className="bg-black text-green-400 p-4 rounded-lg min-h-64 h-80 md:h-96 lg:h-[32rem] max-h-[60vh] w-full overflow-y-auto whitespace-pre-wrap font-mono transition-all duration-200 border border-gray-700" 
            style={{ fontSize: "0.875rem", lineHeight: "1.5" }}
          >
            {currentJob?.log || state.log || (
              <div className="text-gray-500 text-center py-8">
                <div className="mb-2">📋 Ready to start scraping...</div>
                <div className="text-sm">
                  {tool.name === 'IREPS' 
                    ? 'Enter Name and Starting Page, then click "Open Chrome"'
                    : 'Fill in the required fields above and click "Start Scraping"'
                  }
                </div>
              </div>
            )}
            {state.isRunning && <span className="animate-pulse text-green-400">█</span>}
          </div>
        </div>
        {state.stopMessage && (
          <div className="text-red-400 font-semibold mt-2">{state.stopMessage}</div>
        )}

      </div>

      {/* Output Files Section */}
      {(state.runId || currentJob?.runId || state.outputFiles?.length > 0) && (
        <div className="mt-8">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-xl font-bold text-gray-900 dark:text-white">
              📁 Output Files {activeJobState ? `- ${activeJobState}` : ''}
            </h3>
            <div className="flex gap-2">
              <button
                className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg flex items-center gap-2 shadow transition-colors"
                onClick={async () => {
                  if (state.runId) {
                    try {
                      const response = await fetch(`${API_CONFIG.FILE_MANAGER_API}/api/files/${state.runId}`);
                      if (response.ok) {
                        const files = await response.json();
                        setState((prev: any) => ({ ...prev, outputFiles: files }));
                      }
                    } catch (error) {
                      console.log('Failed to refresh files:', error);
                    }
                  }
                }}
                title="Refresh output files"
              >
                🔄 Refresh
              </button>
              <button
                className="bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded-lg flex items-center gap-2 shadow transition-colors"
                onClick={handleMergeFiles}
                disabled={!state.outputFiles || state.outputFiles.length === 0}
              >
                <Merge size={16} /> Merge All Files
              </button>
            </div>
          </div>
          <div className="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-6">
            {/* Show files for the currently active state */}
            {(() => {
              const currentJob = activeJobState ? jobData[activeJobState] : null;
              const filesToShow = currentJob?.outputFiles || state.outputFiles || [];
              
              return filesToShow.length > 0 ? (
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                  {filesToShow.map((file: string) => (
                    <FileCard
                      key={file}
                      file={file}
                      runId={currentJob?.runId || state.runId || ''}
                      setLog={setState}
                      handleDeleteFile={handleDeleteFile}
                      getTimestamp={getTimestamp}
                      isMerged={file.startsWith('merged_data_')}
                      toolName={tool.name}
                      irepsSessionId={irepsSessionId}
                    />
                  ))}
                </div>
              ) : (
                <div className="text-center py-8">
                  <div className="text-gray-500 mb-2">📄 No output files yet</div>
                  <div className="text-sm text-gray-400">
                    {activeJobState 
                      ? `Files for ${activeJobState} will appear here after scraping starts.` 
                      : 'Output files will appear here after scraping starts.'
                    }
                  </div>
                </div>
              );
            })()}
          </div>
        </div>
      )}
    </div>
  );
};

const FileCard: React.FC<{ file: string; runId: string; setLog: (fn: (prev: any) => any) => void; handleDeleteFile: (file: string) => void; getTimestamp: () => string; isMerged?: boolean; toolName: string; irepsSessionId?: string | null }> = React.memo(({ file, runId, setLog, handleDeleteFile, getTimestamp, isMerged, toolName, irepsSessionId }) => {
  const [size, setSize] = React.useState('');
  // Extract just the filename from the full path if needed
  const filename = React.useMemo(() => {
    return file.includes('/') || file.includes('\\') ? file.split(/[/\\]/).pop() || file : file;
  }, [file]);
  
  // Determine if this is an IREPS file and get the correct endpoints
  const isIreps = React.useMemo(() => {
    return toolName === 'IREPS';
  }, [toolName]);
  
  const downloadUrl = React.useMemo(() => {
    if (isIreps && irepsSessionId) {
      return `${API_CONFIG.SCRAPERS_API}/ireps/download/${irepsSessionId}/${filename}`;
    } else {
      return `${API_CONFIG.FILE_MANAGER_API}/api/download/${runId}/${filename}`;
    }
  }, [isIreps, irepsSessionId, runId, filename]);
  
  React.useEffect(() => {
    fetchFileSize(downloadUrl).then(setSize);
  }, [downloadUrl]);
  
  const handleDownload = React.useCallback(() => {
    setLog(prev => ({ ...prev, log: prev.log + `\n${getTimestamp()} File downloaded: ${filename}\n` }));
  }, [setLog, getTimestamp, filename]);
  
  const handleDelete = React.useCallback(() => {
    handleDeleteFile(filename);
  }, [handleDeleteFile, filename]);
  
  return (
    <div className="flex items-center bg-gray-50 dark:bg-gray-800 rounded-lg p-4 gap-3 shadow-sm border border-gray-200 dark:border-gray-700 hover:shadow-md transition-shadow">
      <div className="flex-shrink-0">
        <FileText className="text-blue-500 dark:text-blue-400" size={24} />
      </div>
      <div className="flex-1 min-w-0">
        <div className="truncate text-gray-900 dark:text-gray-200 font-medium text-sm">
          {filename}
          {isMerged && (
            <span className="ml-2 px-2 py-0.5 bg-purple-600 text-white text-xs rounded-full">Merged</span>
          )}
        </div>
        <div className="text-xs text-gray-500 dark:text-gray-400 mt-1">{size}</div>
      </div>
      <div className="flex gap-1">
        <a
          href={downloadUrl}
          className="p-2 text-green-600 hover:text-green-700 dark:text-green-400 dark:hover:text-green-300 rounded hover:bg-green-50 dark:hover:bg-green-900/20 transition-colors"
          title="Download"
          onClick={handleDownload}
        >
          <Download size={16} />
        </a>
        <button
          onClick={handleDelete}
          className="p-2 text-red-600 hover:text-red-700 dark:text-red-400 dark:hover:text-red-300 rounded hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors"
          title="Delete"
        >
          <Trash2 size={16} />
        </button>
      </div>
    </div>
  );
});

FileCard.displayName = 'FileCard';
