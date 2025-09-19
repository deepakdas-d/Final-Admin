import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'lost_report_controller.dart';

class IndividualLostLeadDetails extends StatelessWidget {
  final Map<String, dynamic> lead;

  const IndividualLostLeadDetails({super.key, required this.lead});

  @override
  Widget build(BuildContext context) {
    final LostReportController controller = Get.put(LostReportController());
    final dateFormat = DateFormat('dd-MMM-yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[900],
        title: Text(
          lead['name'] ?? 'Lead Details',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Color(0xFF1A1A1A),
          ),
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lead Info Card
            Card(
              color: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  MediaQuery.of(context).size.width * 0.02,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width * 0.04,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lead Information',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.045,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    _buildDetailRow(
                      context,
                      'Lead ID',
                      lead['leadId'] ?? 'N/A',
                    ),
                    _buildDetailRow(context, 'Name', lead['name'] ?? 'N/A'),
                    _buildDetailRow(
                      context,
                      'Phone 1',
                      lead['phone1'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      context,
                      'Phone 2',
                      lead['phone2'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      context,
                      'Address',
                      lead['address'] ?? 'N/A',
                    ),
                    _buildDetailRow(context, 'Place', lead['place'] ?? 'N/A'),
                    _buildDetailRow(
                      context,
                      'Salesman',
                      lead['salesman'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      context,
                      'Status',
                      lead['status'] ?? 'N/A',
                      valueColor: controller.getStatusTextColor(
                        lead['status'] ?? '',
                      ),
                      valueBackground: controller.getStatusColor(
                        lead['status'] ?? '',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            // Additional Details Card
            Card(
              color: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  MediaQuery.of(context).size.width * 0.02,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width * 0.04,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional Details',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.045,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    _buildDetailRow(
                      context,
                      'Created At',
                      lead['createdAt'] != null
                          ? dateFormat.format(lead['createdAt'])
                          : 'N/A',
                    ),
                    _buildDetailRow(
                      context,
                      'Follow Up Date',
                      lead['followUpDate'] != null
                          ? dateFormat.format(lead['followUpDate'])
                          : 'N/A',
                    ),
                    _buildDetailRow(context, 'Remark', lead['remark'] ?? 'N/A'),
                    _buildDetailRow(
                      context,
                      'Product ID',
                      lead['productID'] ?? 'N/A',
                    ),
                    _buildDetailRow(context, 'NOS', lead['nos'] ?? 'N/A'),
                    _buildDetailRow(
                      context,
                      'Customer ID',
                      lead['customerId'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      context,
                      'Archived',
                      lead['isArchived'] == true ? 'Yes' : 'No',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    Color? valueBackground,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height * 0.015,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.035,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: valueBackground != null
                  ? EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.015,
                      vertical: MediaQuery.of(context).size.height * 0.005,
                    )
                  : null,
              decoration: valueBackground != null
                  ? BoxDecoration(
                      color: valueBackground,
                      borderRadius: BorderRadius.circular(
                        MediaQuery.of(context).size.width * 0.02,
                      ),
                    )
                  : null,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.035,
                  color: valueColor ?? Colors.black87,
                  fontWeight: valueBackground != null
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
                overflow: TextOverflow.visible,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
