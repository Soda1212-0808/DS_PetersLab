function out = ifelse(cond, trueResult, falseResult)
    if cond
        out = trueResult;
    else
        out = falseResult;
    end
end