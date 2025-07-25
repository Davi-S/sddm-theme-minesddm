import QtQuick 2.15

QtObject {
    readonly property string escapeCharacter: "%" // also change the explanation in config file accordingly, if you change this
    required property var placeholderMap

    // Helper function to escape special characters for use in a RegExp
    function escapeRegExp(string) {
        return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    }

    // Generate a unique ID for escape sequences
    function generateUniqueId() {
        return Date.now().toString(36) + Math.random().toString(36).substring(2);
    }

    // Create escape map for pre-processing
    function createEscapeMap(uniqueId) {
        return {
            '%%': `__PERCENT_${uniqueId}__`,
            '%{': `__LEFT_BRACE_${uniqueId}__`,
            '%}': `__RIGHT_BRACE_${uniqueId}__`,
            '%?': `__QUESTION_MARK_${uniqueId}__`,
            '%:': `__COLON_${uniqueId}__`,
        };
    }

    // Pre-process text by replacing escape sequences with temporary placeholders
    function preprocessEscapeSequences(text, escapeMap) {
        let processedText = text;
        for (const seq in escapeMap) {
            if (Object.prototype.hasOwnProperty.call(escapeMap, seq)) {
                const escapedSeq = escapeRegExp(seq);
                processedText = processedText.replace(new RegExp(escapedSeq, 'g'), escapeMap[seq]);
            }
        }
        return processedText;
    }

    // Evaluate conditional expressions (ternary-like syntax with ?)
    function evaluateConditional(content) {
        const qMarkIndex = content.indexOf('?');
        let conditionStr = content.substring(0, qMarkIndex);
        const restStr = content.substring(qMarkIndex + 1);

        // Look up the condition with braces
        const conditionKey = `{${conditionStr}}`;
        if (placeholderMap.has(conditionKey)) {
            conditionStr = placeholderMap.get(conditionKey);
        }

        let trueVal, falseVal;
        const colonIndex = restStr.indexOf(':');

        if (colonIndex !== -1) {
            trueVal = restStr.substring(0, colonIndex);
            falseVal = restStr.substring(colonIndex + 1);
        } else {
            trueVal = restStr;
            falseVal = '';
        }

        return conditionStr ? trueVal : falseVal;
    }

    // Evaluate simple placeholder lookup
    function evaluatePlaceholder(content) {
        const contentKey = `{${content}}`;
        return placeholderMap.has(contentKey)
            ? placeholderMap.get(contentKey)
            : content;
    }

    // Evaluate template content (either conditional or simple placeholder)
    function evaluateTemplateContent(content) {
        if (content.includes('?')) {
            return evaluateConditional(content);
        } else {
            return evaluatePlaceholder(content);
        }
    }

    // Process templates iteratively from innermost to outermost
    function processTemplates(text) {
        const innermostRegex = /\{([^{}]*)\}/;
        let processedText = text;

        while (true) {
            const match = innermostRegex.exec(processedText);
            if (!match) {
                break;
            }

            const content = match[1];
            const evaluationResult = evaluateTemplateContent(content);

            const start = match.index;
            const end = start + match[0].length;
            processedText = processedText.substring(0, start) + evaluationResult + processedText.substring(end);
        }

        return processedText;
    }

    // Post-process text by restoring escaped sequences
    function postprocessEscapeSequences(text, escapeMap) {
        let processedText = text;
        for (const seq in escapeMap) {
            if (Object.prototype.hasOwnProperty.call(escapeMap, seq)) {
                const escapedPlaceholder = escapeRegExp(escapeMap[seq]);
                processedText = processedText.replace(new RegExp(escapedPlaceholder, 'g'), seq.charAt(1));
            }
        }
        return processedText;
    }

    // Main formatting function that orchestrates the entire process
    function formatString(text) {
        const uniqueId = generateUniqueId();
        const escapeMap = createEscapeMap(uniqueId);
        
        // 1. Pre-processing: handle escape sequences
        let processedText = preprocessEscapeSequences(text, escapeMap);
        
        // 2. Process templates iteratively
        processedText = processTemplates(processedText);
        
        // 3. Post-processing: restore escaped characters
        processedText = postprocessEscapeSequences(processedText, escapeMap);
        
        return processedText;
    }

}
