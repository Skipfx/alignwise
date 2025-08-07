import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';


class FriendActivityHeader extends StatelessWidget {
  final int friendCount;
  final VoidCallback onViewAllFriends;

  const FriendActivityHeader({
    Key? key,
    required this.friendCount,
    required this.onViewAllFriends,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.fromLTRB(4.w, 3.w, 4.w, 2.w),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Theme.of(context).primaryColor.withAlpha(26),
              Theme.of(context).primaryColor.withAlpha(13),
            ], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(width: 1)),
        child: Row(children: [
          // Activity indicator icon
          Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(shape: BoxShape.circle),
              child: Icon(Icons.groups_outlined, size: 20.sp)),
          SizedBox(width: 4.w),

          // Activity info
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Friend Activity',
                    style: GoogleFonts.inter(
                        fontSize: 16.sp, fontWeight: FontWeight.w600)),
                SizedBox(height: 1.w),
                Text(
                    friendCount > 0
                        ? 'See what your $friendCount friends are up to'
                        : 'Connect with friends to see their wellness journey',
                    style: GoogleFonts.inter(fontSize: 12.sp)),
              ])),

          // Action button
          Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(friendCount > 0 ? 'View All' : 'Find Friends',
                    style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                SizedBox(width: 1.w),
                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12.sp),
              ])),
        ]));
  }
}