import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/core/services/firebase_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_maintenance_system_new/core/localization/app_localizations.dart';
import 'dart:math';

class AdminInviteCodesPage extends ConsumerStatefulWidget {
  const AdminInviteCodesPage({super.key});

  @override
  ConsumerState<AdminInviteCodesPage> createState() => _AdminInviteCodesPageState();
}

class _AdminInviteCodesPageState extends ConsumerState<AdminInviteCodesPage> {
  final _roleController = TextEditingController(text: 'technician');
  final _maxUsesController = TextEditingController(text: '1');
  bool _isGenerating = false;

  @override
  void dispose() {
    _roleController.dispose();
    _maxUsesController.dispose();
    super.dispose();
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _createInviteCode() async {
    if (_maxUsesController.text.isEmpty || int.tryParse(_maxUsesController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('invalid_max_uses'.tr(ref)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final code = _generateInviteCode();
      final maxUses = int.parse(_maxUsesController.text);
      
      await FirebaseService.firestore.collection('invite_codes').add({
        'code': code,
        'role': _roleController.text,
        'maxUses': maxUses,
        'usedCount': 0,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseService.auth.currentUser?.uid,
        'usedBy': [],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'invite_code_created'.tr(ref)}$code'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'copy'.tr(ref),
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('code_copied'.tr(ref)),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error_creating_code'.tr(ref)}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _toggleCodeStatus(String docId, bool currentStatus, List<dynamic> usedBy) async {
    try {
      // If deactivating the code, handle deactivation flow
      if (currentStatus && usedBy.isNotEmpty) {
        if (mounted) {
          final confirmDeactivateUsers = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'deactivate_users_title'.tr(ref),
                style: TextStyle(fontSize: 18.sp),
              ),
              content: Text(
                'deactivate_users_desc'.tr(ref),
                style: TextStyle(fontSize: 14.sp),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('no'.tr(ref), style: TextStyle(fontSize: 14.sp)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text('yes_deactivate'.tr(ref), style: TextStyle(fontSize: 14.sp)),
                ),
              ],
            ),
          );

          // Update the invite code status
          await FirebaseService.firestore
              .collection('invite_codes')
              .doc(docId)
              .update({'isActive': false});

          if (confirmDeactivateUsers == true) {
            // Deactivate all users who used this invite code
            final batch = FirebaseService.firestore.batch();
            for (final userId in usedBy) {
              final userRef = FirebaseService.firestore.collection('users').doc(userId as String);
              batch.update(userRef, {'isActive': false});
            }
            await batch.commit();
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${'code_deactivated_users_disabled'.tr(ref)} (${usedBy.length})'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('code_deactivated'.tr(ref)),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        }
      } 
      // If activating the code, handle reactivation flow
      else if (!currentStatus && usedBy.isNotEmpty) {
        if (mounted) {
          final confirmReactivateUsers = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'reactivate_users_title'.tr(ref),
                style: TextStyle(fontSize: 18.sp),
              ),
              content: Text(
                'reactivate_users_desc'.tr(ref),
                style: TextStyle(fontSize: 14.sp),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('no'.tr(ref), style: TextStyle(fontSize: 14.sp)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.green),
                  child: Text('yes_reactivate'.tr(ref), style: TextStyle(fontSize: 14.sp)),
                ),
              ],
            ),
          );

          // Update the invite code status
          await FirebaseService.firestore
              .collection('invite_codes')
              .doc(docId)
              .update({'isActive': true});

          if (confirmReactivateUsers == true) {
            // Reactivate all users who used this invite code
            final batch = FirebaseService.firestore.batch();
            for (final userId in usedBy) {
              final userRef = FirebaseService.firestore.collection('users').doc(userId as String);
              batch.update(userRef, {'isActive': true});
            }
            await batch.commit();
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${'code_activated_users_enabled'.tr(ref)} (${usedBy.length})'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('code_activated'.tr(ref)),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      }
      // Simple activation/deactivation with no users
      else {
        await FirebaseService.firestore
            .collection('invite_codes')
            .doc(docId)
            .update({'isActive': !currentStatus});
            
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(!currentStatus ? 'code_activated'.tr(ref) : 'code_deactivated'.tr(ref)),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error_updating_code'.tr(ref)}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _getTechnicianNames(List<dynamic> userIds) async {
    if (userIds.isEmpty) {
      return 'not_used_yet'.tr(ref);
    }

    try {
      final names = <String>[];
      for (final userId in userIds) {
        final userDoc = await FirebaseService.firestore
            .collection('users')
            .doc(userId as String)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          names.add(userData?['name'] ?? 'Unknown');
        }
      }
      return names.isEmpty ? 'Not used yet' : names.join(', ');
    } catch (e) {
      debugPrint('Error fetching technician names: $e');
      return 'error_loading_names'.tr(ref);
    }
  }

  Future<void> _deleteCode(String docId, String code) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'delete_invite_code'.tr(ref),
          style: TextStyle(fontSize: 18.sp),
        ),
        content: Text(
          '${'delete_code_confirm'.tr(ref)}$code?',
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr(ref), style: TextStyle(fontSize: 14.sp)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr(ref), style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseService.firestore
            .collection('invite_codes')
            .doc(docId)
            .delete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('code_deleted_success'.tr(ref)),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'error_deleting_code'.tr(ref)}$e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'invite_codes'.tr(ref),
          style: TextStyle(fontSize: 18.sp),
        ),
      ),
      body: Column(
        children: [
          // Create Invite Code Section
          Card(
            margin: EdgeInsets.all(16.w),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'generate_invite_code'.tr(ref),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _roleController.text,
                          decoration: InputDecoration(
                            labelText: 'role'.tr(ref),
                            labelStyle: TextStyle(fontSize: 14.sp),
                            border: const OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 12.h,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 14.sp, 
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          dropdownColor: Theme.of(context).cardColor,
                          items: [
                            DropdownMenuItem(
                              value: 'technician',
                              child: Text('technician'.tr(ref), style: TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.onSurface)),
                            ),
                            DropdownMenuItem(
                              value: 'cashier',
                              child: Text('cashier'.tr(ref), style: TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.onSurface)),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('admin'.tr(ref), style: TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.onSurface)),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              _roleController.text = value;
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: TextFormField(
                          controller: _maxUsesController,
                          decoration: InputDecoration(
                            labelText: 'max_uses'.tr(ref),
                            labelStyle: TextStyle(fontSize: 14.sp),
                            border: const OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 12.h,
                            ),
                          ),
                          style: TextStyle(fontSize: 14.sp, color: Theme.of(context).textTheme.bodyLarge?.color),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _createInviteCode,
                      icon: _isGenerating
                          ? SizedBox(
                              width: 16.w,
                              height: 16.w,
                              child: CircularProgressIndicator(strokeWidth: 2.w),
                            )
                          : Icon(Icons.add, size: 20.sp),
                      label: Text(
                        _isGenerating ? 'generating'.tr(ref) : 'generate_code'.tr(ref),
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // List of Invite Codes
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.firestore
                  .collection('invite_codes')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final codes = snapshot.data!.docs;

                if (codes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.code_off, size: 64.sp, color: Colors.grey),
                        SizedBox(height: 16.h),
                        Text(
                          'no_invite_codes'.tr(ref),
                          style: TextStyle(fontSize: 16.sp),
                        ),
                        Text(
                          'generate_one_form'.tr(ref),
                          style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: codes.length,
                  itemBuilder: (context, index) {
                    final doc = codes[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final code = data['code'] as String;
                    final role = data['role'] as String;
                    final maxUses = data['maxUses'] as int;
                    final usedCount = data['usedCount'] as int;
                    final isActive = data['isActive'] as bool;
                    final usedBy = (data['usedBy'] as List<dynamic>?) ?? [];

                    return Card(
                      margin: EdgeInsets.only(bottom: 12.h),
                      child: Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isActive ? Colors.green : Colors.grey,
                                  radius: 20.r,
                                  child: Icon(
                                    isActive ? Icons.check : Icons.block,
                                    color: Colors.white,
                                    size: 20.sp,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              code,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'monospace',
                                                fontSize: 16.sp,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          InkWell(
                                            onTap: () {
                                              Clipboard.setData(ClipboardData(text: code));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'code_copied'.tr(ref),
                                                    style: TextStyle(fontSize: 14.sp),
                                                  ),
                                                  duration: const Duration(seconds: 2),
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.all(4.w),
                                              child: Icon(Icons.copy, size: 18.sp),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8.h),
                                      Wrap(
                                        spacing: 8.w,
                                        runSpacing: 4.h,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8.w,
                                              vertical: 4.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12.r),
                                            ),
                                            child: Text(
                                              role.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).brightness == Brightness.dark 
                                                    ? Colors.white 
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${'uses'.tr(ref)} $usedCount/$maxUses',
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w500,
                                              color: Theme.of(context).textTheme.bodyMedium?.color,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (usedBy.isNotEmpty) ...[
                                        SizedBox(height: 8.h),
                                        FutureBuilder<String>(
                                          future: _getTechnicianNames(usedBy),
                                          builder: (context, snapshot) {
                                            return Row(
                                              children: [
                                                Icon(
                                                  Icons.person,
                                                  size: 14.sp,
                                                  color: Colors.blue[700],
                                                ),
                                                SizedBox(width: 4.w),
                                                Expanded(
                                                  child: Text(
                                                    '${'used_by'.tr(ref)} ${snapshot.data ?? 'loading'.tr(ref)}',
                                                    style: TextStyle(
                                                      fontSize: 12.sp,
                                                      color: Colors.blue[700],
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                PopupMenuButton(
                                  padding: EdgeInsets.zero,
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      child: Row(
                                        children: [
                                          Icon(
                                            isActive ? Icons.block : Icons.check_circle,
                                            size: 18.sp,
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(
                                            isActive ? 'deactivate'.tr(ref) : 'activate'.tr(ref),
                                            style: TextStyle(fontSize: 14.sp),
                                          ),
                                        ],
                                      ),
                                      onTap: () => _toggleCodeStatus(doc.id, isActive, usedBy),
                                    ),
                                    PopupMenuItem(
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            size: 18.sp,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(
                                            'delete'.tr(ref),
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: () => _deleteCode(doc.id, code),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


