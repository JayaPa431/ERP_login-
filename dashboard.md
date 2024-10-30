<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Admin Dashboard - Maryland Comptroller</title>
<style>
  /* Basic styles */
  body {
    font-family: Arial, sans-serif;
    background-color: #f4f4f4;
    margin: 0;
    padding: 0;
  }

  /* Header styles */
  .header {
    display: flex;
    justify-content: space-between;
    padding: 10px 20px;
    background-color: #007bff;
    color: white;
  }

  .header .logout {
    color: white;
    text-decoration: none;
    font-weight: bold;
  }

  /* Main content styles */
  .content {
    padding: 20px;
  }

  .content h2 {
    text-align: center;
  }

  /* Table styles */
  .table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 20px;
  }

  .table th, .table td {
    padding: 12px;
    border: 1px solid #ddd;
    text-align: center;
  }

  .table th {
    background-color: #007bff;
    color: white;
  }

  /* Button styles */
  .action-buttons button {
    padding: 5px 10px;
    margin: 0 2px;
    border: none;
    border-radius: 4px;
    color: white;
    cursor: pointer;
  }

  .accept { background-color: #28a745; }
  .reject { background-color: #dc3545; }

  /* Footer styles */
  .footer {
    display: flex;
    justify-content: space-between;
    padding: 10px 20px;
    background-color: #f4f4f4;
    font-size: 14px;
    color: #555;
    margin-top: 20px;
    border-top: 1px solid #ddd;
  }

  .footer a {
    color: #007bff;
    text-decoration: none;
  }
</style>
</head>
<body>

<!-- Header -->
<div class="header">
  <div>
    <a href="#" onclick="history.back(); return false;">Back</a>
  </div>
  <div>
    <span>Name</span> | <span>UserID</span> | 
    <a href="login.html" class="logout">Logout</a>
  </div>
</div>

<!-- Content -->
<div class="content">
  <h2>Admin Dashboard - Request Status</h2>
  <table class="table">
    <tr>
      <th>Form No</th>
      <th>Title</th>
      <th>Submitted Date</th>
      <th>Pending Days</th>
      <th>Actions</th>
    </tr>
    <!-- Example row with placeholder dates -->
    <tr>
      <td>123</td>
      <td>Request Title A</td>
      <td class="submitted-date">2024-10-01</td>
      <td class="pending-days"></td>
      <td class="action-buttons">
        <button class="accept" onclick="acceptRequest(123)">Accept</button>
        <button class="reject" onclick="rejectRequest(123)">Reject</button>
      </td>
    </tr>
    <tr>
      <td>124</td>
      <td>Request Title B</td>
      <td class="submitted-date">2024-10-15</td>
      <td class="pending-days"></td>
      <td class="action-buttons">
        <button class="accept" onclick="acceptRequest(124)">Accept</button>
        <button class="reject" onclick="rejectRequest(124)">Reject</button>
      </td>
    </tr>
  </table>
</div>

<!-- Footer -->
<div class="footer">
  <div>+1965-000-0000</div>
  <div><a href="mailto:ombudsman@marylandtaxes.gov">ombudsman@marylandtaxes.gov</a></div>
  <div><a href="https://www.example.com">www.example.com</a></div>
  <div><a href="help.html">Help/Support</a></div>
</div>

<script>
  // Calculate pending days dynamically
  document.addEventListener("DOMContentLoaded", function() {
    const rows = document.querySelectorAll("table.table tr");
    rows.forEach(row => {
      const submittedDateElement = row.querySelector(".submitted-date");
      const pendingDaysElement = row.querySelector(".pending-days");
      const actionButtons = row.querySelector(".action-buttons");

      if (submittedDateElement && pendingDaysElement) {
        const submittedDate = new Date(submittedDateElement.innerText);
        const currentDate = new Date();
        const pendingDays = Math.floor((currentDate - submittedDate) / (1000 * 60 * 60 * 24));
        
        pendingDaysElement.innerText = pendingDays >= 0 ? pendingDays + " days" : "N/A";

        // Enable/disable buttons based on pending days
        if (pendingDays > 0) {
          actionButtons.querySelector(".accept").disabled = false;
          actionButtons.querySelector(".reject").disabled = false;
        } else {
          actionButtons.querySelector(".accept").disabled = true;
          actionButtons.querySelector(".reject").disabled = true;
        }
      }
    });
  });

  // Action functions with basic confirmation
  function acceptRequest(id) {
    if (confirm("Are you sure you want to accept request " + id + "?")) {
      alert("Request " + id + " has been accepted.");
      // Further code for backend update could go here
    }
  }

  function rejectRequest(id) {
    if (confirm("Are you sure you want to reject request " + id + "?")) {
      alert("Request " + id + " has been rejected.");
      // Further code for backend update could go here
    }
  }
</script>

</body>
</html>
