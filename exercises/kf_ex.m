%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% S-114.4202 Research Seminar on Computational Science
% Bayesian Estimation of Time-Varying Processes (5 p) L V
%
% $Id: kf_ex.m,v 1.1 2009/03/30 17:00:18 ssarkka Exp $
%
% This software is distributed under the GNU General Public 
% Licence (version 2 or later); please refer to the file 
% Licence.txt, included with the software, for details.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % Generate data
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  randn('state',123);
  steps = 100;

  w = 0.5;
  q = 0.01;
  r = 0.1;

  % This is the transition matrix
  A = [cos(w)    sin(w)/w; 
       -w*sin(w) cos(w)];

  % This is the process noise covariance
  Q = [0.5*q*(w-cos(w)*sin(w))/w^3 0.5*q*sin(w)^2/w^2;
       0.5*q*sin(w)^2/w^2          0.5*q*(w+cos(w)*sin(w))/w];

  % This is the true initial value
  x0 = [0;0.1]; 

  X = zeros(2,steps);  % The true signal
  Y = zeros(1,steps);  % Measurements
  T = 1:steps;         % Time
  x = x0;
  for k=1:steps
    x = mvnrnd(A*x,Q)';
    y = mvnrnd(x(1),r);
    X(:,k) = x;
    Y(:,k) = y;
  end

  %figure;
  %subplot(1,1,1);
  %plot(T,X(1,:),'--',T,Y,'o');
  %legend('True signal','Measurements');
  %fprintf('This is the simulated data. Press enter.\n');
  %pause;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % Base line solution. The estimates
  % of x_k are stored as columns of
  % the matrix EST1.
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  m1 = x0;  % Initialize to true value
  EST1 = zeros(2,steps);
  for k=1:steps
    m1(2) = Y(k)-m1(1);
    m1(1) = Y(k);

    EST1(:,k) = m1;
  end

  % Plot the signal and its estimate
  figure;
  subplot(2,1,1);
  plot(T,X(1,:),'-',T,EST1(1,:),'--',T,Y,'k.','MarkerSize',8);
  legend('True signal','Estimated signal','Measurements');
  
  % Plot the derivative and its estimate
  subplot(2,1,2);
  plot(T,X(2,:),'-',T,EST1(2,:),'--');
  legend('True derivative','Estimated derivative');
  exportplot('ex_3_3_basesol.pdf',figW,figH,gcf,1.5);
  % Compute error
  err1 = rmse(X,EST1);
  
  fprintf('This is the base line estimate. Press enter.\n');
  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Kalman filter solution
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  m = x0;     % Initialize to true value
  P = eye(2); % Some uncertanty in covariance  
  EST2 = zeros(2,steps);
  EST2P = zeros(2,2,steps);
  
  Ks = EST2;
  H = [1 0];
  kdiff = zeros(1,steps);
  for k=1:steps
    % prediction
    m_ = A*m;
    P_ = A*P*A'+Q;
    
    % update
    K = P_(:,1)/(P_(1,1)+r);
    Ks(:,k) = K;
    m = m_ + K*(Y(k)-m_(1));
    P = P_-(P_(1,1)+r)*(K*K');

    % Store the results
    EST2(:,k) = m;
    EST2P(:,:,k) = P;
  end

  % Plot the signal and its estimate
  figure;
  subplot(2,1,1);
  plot(T,X(1,:),'-',T,EST2(1,:),'--',T,Y,'k.','MarkerSize',8);
  legend('True signal','Estimated signal','Measurements');
  
  % Plot the derivative and its estimate
  subplot(2,1,2);
  plot(T,X(2,:),'-',T,EST2(2,:),'--');
  legend('True derivative','Estimated derivative');
  exportplot('ex_3_3_kalmansol.pdf',figW,figH,gcf,1.5);


  % Compute error
  err2 = rmse(X,EST2);  



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Stationary Kalman filter solution
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  m3 = x0;     % Initialize to true value
  K  =  [0.424975200169185;
         0.111137301539005];  % Store the stationary gain here
  
  EST3 = zeros(2,steps);

  for k=1:steps
    % Replace these with the stationary Kalman filter equations
    m3 = A*m3+K*(Y(k)-A(1,:)*m3);
    
    % Store the results
    EST3(:,k) = m3;
  end

  % Plot the signal and its estimate
  figure;
  subplot(2,1,1);
  plot(T,X(1,:),'-',T,EST3(1,:),'--',T,Y,'k.','MarkerSize',8);
  legend('True signal','Estimated signal','Measurements');
  
  % Plot the derivative and its estimate
  subplot(2,1,2);
  plot(T,X(2,:),'-',T,EST3(2,:),'--');
  legend('True derivative','Estimated derivative');
  exportplot('ex_3_3_statkalmansol.pdf',figW,figH,gcf,1.5);
  
  
  % Compute error
  err3 = rmse(X,EST3);
  
    rLabels = {'RMSE'};
    cLabels = {'Baseline' 'Kalman' 'Stat. Kalman'};
    matrix2latex([err1 err2 err3],'ex_3_3_rmse.tex',...
           'alignment','d{?}{2}','format','$%.5f$','columnLabels',cLabels,...
           'rowLabels',rLabels,'rowLabelAlignment','r');
  
 
 %%

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % RTS Smoother
  % The estimates of x_k are stored as columns of
  % the matrix EST3.
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mss = zeros(2,steps);
Pss = EST2P;
Gs = Pss;
P2s = Pss;
m_s = EST2(:,end);
P_s = EST2P(:,:,end);
mss(:,end) = m_s;
Pss(:,:,end) = P_s;
P2s(:,:,end) = (eye(2)-K*H)*A*Pss(:,:,end-1); % covariance across 2 timesteps
for k=steps-1:-1:1
    m = EST2(:,k);
    P = EST2P(:,:,k);
    % prediction
    m_ = A*m;
    P_ = A*P*A'+Q;
    
    % update
    G = P*A'/P_;
    m_s = m + G*(m_s-m_);
    P_s = P + G*(P_s-P_)*G';
    P_2s = P*G'+Gs(:,:,k+1)*(P2s(:,:,k+1)-A*P)*G';
    
    Gs(:,:,k) = G;
    mss(:,k) = m_s;
    Pss(:,:,k) = P_s;
    P2s(:,:,k) = P_2s;
    
end

% Plot the signal and its estimate
figure;
subplot(2,1,1);
plot(T,EST2(1,:),'-',T,EST3(1,:),'--');
legend('Kalman','RTS');
xlabel('Time');
ylabel('Mean');

% Plot the derivative and its estimate
subplot(2,1,2);
plot(T,EST2(2,:),'-',T,EST3(2,:),'--');
legend('Kalman','RTS');
xlabel('Time');
ylabel('Mean');

%exportplot('ex_7_2.pdf',figW,figH,gcf,1.5);
err4 = rmse(X,mss);
  
% rLabels = {'RMSE'};
% cLabels = {'Baseline' 'Kalman' 'Stat. Kalman' 'RTS'};
% matrix2latex([err1 err2 err3 err4],'ex_7_2_rmse.tex',...
%        'alignment','d{?}{2}','format','$%.5f$','columnLabels',cLabels,...
%        'rowLabels',rLabels,'rowLabelAlignment','r');  
  


