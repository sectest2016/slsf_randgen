classdef blockchooser < handle
    %BLOCKCHOOSER Choose which blocks to use in random generator
    %Can blocklist some blocks
    %   Detailed explanation goes here
    
    properties
        
        % When using a fitness proportionate algorithm (e.g. roulette
        % wheel), probability of each category is denoted by the field
        % `num`.  NOTE THAT MAXIMUM VALUE OF num CAN BE 1.0
        
        categories = {
            struct('name', 'Discrete', 'num', 0.8)
%             struct('name', 'Continuous', 'num', 0)
%             struct('name', 'Math Operations', 'num', 10)
%             struct('name', 'Logic and Bit Operations', 'num', 10)
            struct('name', 'Sinks', 'num', 0.1)
            struct('name', 'Sources', 'num', 0.1)
        };
    
        
    
        allowlist = {
            struct('name', 'simulink/Ports & Subsystems/Model', 'num', 0.1)
            struct('name', 'simulink/Ports & Subsystems/For Each Subsystem', 'num', 0.1)
        };
%         allowlist = {};

        all_cats = [];                       % Will be processed later
    
        blocklist = struct;
        
        hierarchy_blocks = mymap();
        submodel_blocks = mymap();
        
        selection_stat = [];
    end
    
    methods
        
        
        function obj=blockchooser()
            % CONSTRUCTOR %
            
            % Blacklist some blocks
            obj.blocklist.(util.mvn('simulink/Sources/From File')) = 1;
            obj.blocklist.(util.mvn('simulink/Sources/FromWorkspace')) = 1;
            obj.blocklist.(util.mvn('simulink/Sources/EnumeratedConstant')) = 1;
            obj.blocklist.(util.mvn('simulink/Discrete/Discrete Derivative')) = 1;
            obj.blocklist.(util.mvn('simulink/Math Operations/FindNonzeroElements')) = 1;
            obj.blocklist.(util.mvn('simulink/Continuous/VariableTransport Delay')) = 1;
            obj.blocklist.(util.mvn('simulink/Sinks/StopSimulation')) = 1;
%             obj.blocklist.(util.mvn('simulink/Continuous/PID Controller (2DOF)')) = 1;

            % List the hierarchy blocks
            obj.hierarchy_blocks.put('simulink/Ports & Subsystems/Model', 1);

            % List the submodel-blocks
            obj.submodel_blocks.put('simulink/Ports & Subsystems/For Each Subsystem', 1);
        end
        
        
        function ret = is_hierarchy_block(obj, bname)
            ret = obj.hierarchy_blocks.contains(bname);
        end
        
        function ret = is_submodel_block(obj, bname)
            ret = obj.submodel_blocks.contains(bname);
        end
        
        
        function obj = process_cats(obj, can_not_choose_hierarchy_blocks)
            fprintf('PROCESSING ALL CATEGORIES...\n');
            obj.all_cats = obj.categories;
            num_all_cats = numel(obj.categories);
            
            for i = 1:numel(obj.allowlist)
                c = obj.allowlist{i};
                
                if can_not_choose_hierarchy_blocks && (obj.hierarchy_blocks.contains(c.name) || obj.submodel_blocks.contains(c.name))
                    fprintf('Can not add %s: max level reached.\n', c.name);
                    continue;
                end
                
                num_all_cats = num_all_cats + 1;
                obj.all_cats{num_all_cats} = c;
%                 obj.all_cats{num_all_cats} = struct('name', c.name, 'num', c.num, 'is_scalar', true);
            end
        end
        
        function obj = do_selection_stat(obj, counter, num_choose)
            obj.selection_stat = mymap();
            
            for i = 1:numel(obj.all_cats)
                obj.selection_stat.put(obj.all_cats{i}.name, counter(i)/num_choose);
            end
        end
        
        
        function ret = get(obj, cur_hierarchy_level, max_hierarchy_level, num_choose)
            % Selects block names randomly
            ret = mycell(-1);
            can_not_choose_hierarchy_blocks = cur_hierarchy_level >= max_hierarchy_level;
            
            obj.process_cats(can_not_choose_hierarchy_blocks);
            
            % Debug
            for i = 1:numel(obj.all_cats)
                c = obj.all_cats{i};
                fprintf('%s\t%d\n',c.name, c.num);
            end
            
            counts = util.roulette_wheel(obj.all_cats, num_choose);
            obj.do_selection_stat(counts, num_choose);
            
            for i=1:numel(obj.categories)
                c = obj.categories{i};
                fprintf('Choosing %d elements from %s\n', counts(i), c.name);
                
                all_blocks = find_system(['Simulink/' c.name]);
                num_all_blocks = numel(all_blocks) - 1; % Skip the first
                
                rand_vals = randi([2, num_all_blocks], 1, counts(i)); % Generates starting at 2
            
                for index = 1:counts(i)
                    now_blk = all_blocks{rand_vals(index)};
                    
                    while isfield(obj.blocklist, util.mvn(now_blk))
                        i_rand = randi([2, num_all_blocks], 1, 1);
                        now_blk = all_blocks{i_rand};
                    end

                    ret.add(now_blk);
                end                
             
            end
            
            fprintf('Now adding must-have blocks... \n');
            counts_counter = numel(obj.all_cats) - numel(obj.allowlist) + 1
            
            for i=counts_counter:numel(obj.all_cats)
                cur = obj.all_cats{i}.name;
                
                fprintf('About to add BLOCK %s FROM ALLOWLIST %d times\n', cur, counts(i));
                
                for j=1:counts(i)
                    ret.add(cur);
                end

            end
        end
        
        
%         function ret = get(obj, cur_hierarchy_level, max_hierarchy_level)
%             % Selects block names randomly
%             ret = mycell(-1);
%             can_not_choose_hierarchy_blocks = cur_hierarchy_level >= max_hierarchy_level;
%                         
%             % Chose from whitelisted Simulink Libraries
%             
%             for i=1:numel(obj.categories)
%                 c = obj.categories{i};
%                 
%                 disp(['(c) Choosing from: ' c.name]);
%                 
%                 all_blocks = find_system(['Simulink/' c.name]);
%                 num_all_blocks = numel(all_blocks) - 1; % Skip the first
%                 
%                 for j = 2:num_all_blocks
%                     now_blk = all_blocks{j};
%                     
%                     if isfield(obj.blocklist, util.mvn(now_blk))
%                         continue;
%                     end
%                     
%                     ret.add({now_blk, c.num});
%                     
%                 end
%                 
% %                 rand_vals = randi([2, num_all_blocks], 1, c.num); % Generates starting at 2
% %             
% %                 for index = 1:c.num
% %                     now_blk = all_blocks{rand_vals(index)};
% %                     
% %                     while isfield(obj.blocklist, util.mvn(now_blk))
% %                         i_rand = randi([2, num_all_blocks], 1, 1);
% %                         now_blk = all_blocks{i_rand};
% %                     end
% % 
% %                     count = count + 1;
% %                     ret{count} = now_blk;
% %                 end
%             end
%             
%             fprintf('Now including blocks from Allowlist...\n');
%             
%             for i=1:numel(obj.allowlist)
%                 
%                 cur = obj.allowlist{i}.name;
%                 
%                 fprintf('HIER BLOCK FROM ALLOWLIST: %s\n', cur);
%                 
%                 if can_not_choose_hierarchy_blocks && (obj.hierarchy_blocks.contains(cur) || obj.submodel_blocks.contains(cur))
%                     fprintf('Can not add hierarchy block %s as max level reached.\n', cur);
%                     continue;
%                 end
%                 
%                 ret.add({cur, obj.allowlist{i}.num});
%             end
%             
%         end
        
    end
    
end

