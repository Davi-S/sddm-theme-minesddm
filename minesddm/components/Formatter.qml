import QtQuick 2.15

QtObject {
    // also change the explanation in config file accordingly, if you change the escapeCharacter
    readonly property string escapeCharacter: "%"
    required property var placeholderMap

    // Helper function to escape special characters for use in a RegExp,
    // since replaceAll is not being accepted as a function.
    function escapeRegExp(string) {
        return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    }

    // Generate a unique ID for escape sequences based on the time and random numbers
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

    // Evaluate a single conditional expression (ternary operator)
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
        if (placeholderMap.has(contentKey)) {
            return placeholderMap.get(contentKey);
        } else {
            showError(`Invalid placeholder: "{${content}}"`);
            // Return empty string on error
            return ""; 
        }
    }

    // Evaluate template content (either conditional or simple placeholder)
    function evaluateTemplateContent(content) {
        if (content.includes('?')) {
            return evaluateConditional(content);
        } else {
            return evaluatePlaceholder(content);
        }
    }

    // Process templates from inside out
    function processTemplates(text) {
        // This pattern finds a matched pair of curly braces that does not contain any other braces inside it
        // These are the innermost templates to work on.
        // Placeholders will be evaluated before the ternary expressions
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
            // Rebuilds the original string with the placeholder value
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
        // Check for empty/undefined input
        if (!text) {
            return "";
        }

        // Pre-processing to handle escape sequences.
        // This effectively makes the special characters invisible
        // to the main processing logic

        // The point of the uniqueId is to prevent an accidental collision
        // if the user's text also contain the same string we're using for a placeholder.
        // This is like killing an ant with an RPG, but why not?
        const uniqueId = generateUniqueId();
        const escapeMap = createEscapeMap(uniqueId);
        let processedText = preprocessEscapeSequences(text, escapeMap);
        
        // Process the template (do not need to care about escaped characters)
        processedText = processTemplates(processedText);
        
        // Check for unmatched braces
        // After all the valid templates have been processed,
        // there shouldn't be any curly braces left.
        // If there are, it means the template was malformed.
        // In this case, return the original text.
        if (processedText.includes('{')) {
            showError("formatString: unmatched '{' found in template.");
            return text; 
        }
        if (processedText.includes('}')) {
            showError("formatString: unmatched '}' found in template.");
            return text;
        }
        
        // Post-processing to restore escaped characters
        processedText = postprocessEscapeSequences(processedText, escapeMap);
        
        return processedText;
    }

}
