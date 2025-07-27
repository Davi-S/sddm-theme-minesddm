import QtQuick 2.15

QtObject {
    // also change the explanation in config file accordingly, if you change the escapeCharacter
    readonly property string escapeCharacter: "%"
    required property var placeholderMap
    readonly property var escapeMap: ({
        [escapeCharacter + escapeCharacter]: '__ESCAPED_ESCAPE_CHARACTER__',
        [escapeCharacter + '{']: '__ESCAPED_LEFT_BRACE__',
        [escapeCharacter + '}']: '__ESCAPED_RIGHT_BRACE__',
        [escapeCharacter + '?']: '__ESCAPED_QUESTION_MARK__',
        [escapeCharacter + ':']: '__ESCAPED_COLON__'
    })

    // Main formatting function that orchestrates the entire process
    function formatString(text) {
        if (!text) return "";

        // Pre-processing to handle escape sequences.
        // This effectively makes the special characters invisible
        // to the main processing logic
        let processedText = hideEscapes(text);
        
        // Process the template
        // This process function must receive the template without any escaped
        // characters. This is why there is preprocessing.
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
        
        // Post-processing to restore the temporary "placeholders"
        processedText = restoreEscapes(processedText);
        
        return processedText;
    }

    // Process text by replacing escaped characters with temporary "placeholders"
    // that will not be processed by the Formatter
    function hideEscapes(text) {
        let processedText = text;
        for (const seq in escapeMap) {
            if (Object.prototype.hasOwnProperty.call(escapeMap, seq)) {
                processedText = processedText.replace(new RegExp(escapeRegExp(seq), 'g'), escapeMap[seq]);
            }
        }
        return processedText;
    }

    // Process text by restoring the temporary "placeholders" created by
    // hideEscapes into their actual values
    function restoreEscapes(text) {
        let processedText = text;
        for (const seq in escapeMap) {
            if (Object.prototype.hasOwnProperty.call(escapeMap, seq)) {
                processedText = processedText.replace(new RegExp(escapeRegExp(escapeMap[seq]), 'g'), seq.charAt(1));
            }
        }
        return processedText;
    }

    // Process templates from inside out
    function processTemplates(text) {
        // This pattern finds a matched pair of curly braces that does not contain any other braces inside it
        // These are the innermost templates to work on.
        // Placeholders will usually be evaluated before the ternary expressions
        const innermostRegex = /\{([^{}]*)\}/;
        let processedText = text;

        while (true) {
            const match = innermostRegex.exec(processedText);
            if (!match) break;
            const content = match[1];
            const evaluationResult = evaluateTemplateContent(content);
            const start = match.index;
            const end = start + match[0].length;
            // Rebuilds the original string with the placeholder value
            processedText = processedText.substring(0, start) + evaluationResult + processedText.substring(end);
        }

        return processedText;
    }

    // Evaluate template content (either conditional or simple placeholder)
    function evaluateTemplateContent(content) {
        if (content.includes('?')) {
            return evaluateConditional(content);
        } else {
            return evaluatePlaceholder(content);
        }
    }

    // Evaluate simple placeholder lookup
    function evaluatePlaceholder(content) {
        const contentKey = `{${content}}`;
        if (placeholderMap.has(contentKey)) {
            let value = placeholderMap.get(contentKey);
            // We need to escape and hide the value to ensure that if it contains
            // especial characters, they are not flag as unmatched curly-braces 
            // nor tried to be evaluated in the future.
            value = escapeSpecialChars(value);
            value = hideEscapes(value);
            return value
        } else {
            showError(`Invalid placeholder: "{${content}}"`);
            return "";
        }
    }

    // Evaluate a single conditional expression (ternary operator)
    function evaluateConditional(content) {
        // Gets the value before the "?" as the conditional and
        // try to replace it if it is a placeholder
        const qMarkIndex = content.indexOf('?');
        let conditionStr = content.substring(0, qMarkIndex);
        if (placeholderMap.has(conditionStr)) {
            conditionStr = placeholderMap.get(conditionStr);
        }

        // splits the rest of the content on ":" into
        // the value-if-true and the value-if-false
        const restStr = content.substring(qMarkIndex + 1);
        const colonIndex = restStr.indexOf(':');
        let trueVal, falseVal;
        if (colonIndex !== -1) {
            trueVal = restStr.substring(0, colonIndex);
            falseVal = restStr.substring(colonIndex + 1);
        } else {
            trueVal = restStr;
            falseVal = '';
        }

        return conditionStr ? trueVal : falseVal;
    }

    // Will escape all special characters in the text
    // "{" to "<escapeCharacter>{"; "?" to "<escapeCharacter>?"; etc...
    function escapeSpecialChars(text) {
        let result = text;
        // The escape character must be replaced first to avoid escaping the escape character in "<escapeCharacter>{" etc.
        const escapePattern = new RegExp(escapeRegExp(escapeCharacter), 'g');
        result = result.replace(escapePattern, escapeCharacter + escapeCharacter);
        result = result.replace(/\{/g, escapeCharacter + "{");
        result = result.replace(/\}/g, escapeCharacter + "}");
        result = result.replace(/\?/g, escapeCharacter + "?");
        result = result.replace(/:/g, escapeCharacter + ":");
        return result;
    }

    // Helper function to escape special characters for use in a RegExp,
    // since replaceAll is not being accepted as a function.
    function escapeRegExp(text) {
        return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    }
    
}
