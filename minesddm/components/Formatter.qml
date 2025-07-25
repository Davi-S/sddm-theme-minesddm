import QtQuick 2.15

QtObject {
    readonly property string escapeCharacter: "%" // also change the explanation in config file accordingly, if you change this
    required property var placeholderMap

    function formatString(text) {
        // Helper function to escape special characters for use in a RegExp
        function escapeRegExp(string) {
            return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        }

        // --- 1. Pre-processing (No changes needed here) ---
        const uniqueId = Date.now().toString(36) + Math.random().toString(36).substring(2);
        const escapeMap = {
            '%%': `__PERCENT_${uniqueId}__`,
            '%{': `__LEFT_BRACE_${uniqueId}__`,
            '%}': `__RIGHT_BRACE_${uniqueId}__`,
            '%?': `__QUESTION_MARK_${uniqueId}__`,
            '%:': `__COLON_${uniqueId}__`,
        };
        let processedText = text;
        for (const seq in escapeMap) {
            if (Object.prototype.hasOwnProperty.call(escapeMap, seq)) {
                 const escapedSeq = escapeRegExp(seq);
                 processedText = processedText.replace(new RegExp(escapedSeq, 'g'), escapeMap[seq]);
            }
        }

        // --- 2. Evaluate templates iteratively ---
        const innermostRegex = /\{([^{}]*)\}/;

        while (true) {
            const match = innermostRegex.exec(processedText);
            if (!match) {
                break;
            }

            const content = match[1];
            let evaluationResult = '';

            if (content.includes('?')) {
                const qMarkIndex = content.indexOf('?');
                let conditionStr = content.substring(0, qMarkIndex);
                const restStr = content.substring(qMarkIndex + 1);

                // --- FIX #1: Look up the condition with braces ---
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
                
                if (conditionStr) {
                    evaluationResult = trueVal;
                } else {
                    evaluationResult = falseVal;
                }
            } else {
                // --- FIX #2: Look up the content with braces ---
                const contentKey = `{${content}}`;
                evaluationResult = placeholderMap.has(contentKey)
                    ? placeholderMap.get(contentKey)
                    : content;
            }

            const start = match.index;
            const end = start + match[0].length;
            processedText = processedText.substring(0, start) + evaluationResult + processedText.substring(end);
        }

        // --- 3. Post-processing (No changes needed here) ---
        for (const seq in escapeMap) {
            if (Object.prototype.hasOwnProperty.call(escapeMap, seq)) {
                const escapedPlaceholder = escapeRegExp(escapeMap[seq]);
                processedText = processedText.replace(new RegExp(escapedPlaceholder, 'g'), seq.charAt(1));
            }
        }

        return processedText;
    }

}
