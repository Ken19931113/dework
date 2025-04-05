import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { ConnectKitProvider } from 'connectkit';
import { WagmiConfig } from 'wagmi';

import Header from './components/Header';
import Footer from './components/Footer';
import Home from './pages/Home';
import Dashboard from './pages/Dashboard';
import CreateRental from './pages/CreateRental';
import Connect from './pages/Connect';
import HowItWorks from './pages/HowItWorks';
import NotFound from './pages/NotFound';

import { wagmiConfig } from './utils/wagmiConfig';

const App = () => {
  return (
    <WagmiConfig config={wagmiConfig}>
      <ConnectKitProvider>
        <Router>
          <div className="flex flex-col min-h-screen">
            <Header />
            <main className="flex-grow bg-gray-50">
              <Routes>
                <Route path="/" element={<Home />} />
                <Route path="/dashboard" element={<Dashboard />} />
                <Route path="/create-rental" element={<CreateRental />} />
                <Route path="/connect" element={<Connect />} />
                <Route path="/how-it-works" element={<HowItWorks />} />
                <Route path="*" element={<NotFound />} />
              </Routes>
            </main>
            <Footer />
          </div>
        </Router>
      </ConnectKitProvider>
    </WagmiConfig>
  );
};

export default App;
