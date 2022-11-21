if size(subj) < n_proc
    n_proc = size(subj,2);
end
subs_split = splitvect(subj, n_proc);

for process = 1:size(subs_split,2)
    
    for sub = 1:size(subs_split{process},2)
        
        name = sprintf('sub%03d',subs_split{process}(sub));
        
    end
    
end