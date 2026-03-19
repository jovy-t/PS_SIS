/* LOCATION: web_root/scripts/StartPage_Alerts.js

   PURPOSE:
   Controls visibility of Start Page alerts.

   Each alert generates student links with a unique CSS class.
   This script counts those links and hides the alert if none exist.

   This prevents empty alerts from appearing on the PowerSchool Start Page.

   RELATED FILES:
   - wildcards/d63_start_page_alerts.txt
   - wildcards/d63_spa/*.txt
*/


/* =========================================================
   EO DIM ALERT
   =========================================================
   Counts students returned from the EO DIM wildcard query.
   If no students are returned, hide the alert container.
*/

var eodimcount = $j('a.eodim-students').length;

if (eodimcount == 0) {

    /* Hide alert if no students found */
    $j('p#eodim').hide();

} else {

    /* Show alert if students exist */
    $j('p#eodim').show();

}