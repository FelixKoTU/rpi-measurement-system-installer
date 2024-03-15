<?php
// Redirect to index.html and then restart raspberry pi.
header("Location: ../index.html");
flush();
exec("sudo /sbin/shutdown -r now");
exit;
?>
