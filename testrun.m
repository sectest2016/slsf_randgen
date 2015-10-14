num_run = 100;    % Number of times the loop will run

% Some vars for our S-function "randsfun" 
s=5;
A = [1.5, 2, 9];

while num_run > 0
    disp(num_run);
    system('./run_from_matlab.sh');
    
    %system('./timeout.sh ./run_from_matlab.sh');   % Don't do this, timeout causes
    %incomplete C file generated by Csmith
    mex randsfun.c;
    
    % We can uncomment following files to run the S-function. Hazard: Will
    % need to force-quit Matlab if randgen.c does not terminate.
    
    disp('Now Calling our S-function randsfun...');
    B=randsfun(s, A);
    num_run = num_run - 1;
end

