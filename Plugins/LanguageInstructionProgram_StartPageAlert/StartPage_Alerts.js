/* FILE: wildcards/d63_start_page_alerts.txt
   INSTRUCTION: Add to <script> section at the bottom.
*/

// 1. Calculate how many EL students were found
var elnolipcount = $j('a.elnolip-students').length;

// 2. IMPORTANT: Must add + elnolipcount to the totalcount variable above!

// 3. Logic to hide the alert header if no students are found
if (elnolipcount == 0) { 
    $j('p#elnolip').hide(); 
} else {
    $j('p#elnolip').show();
}