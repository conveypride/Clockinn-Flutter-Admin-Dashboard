import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'sidebar.dart';

class BaseLayout extends StatelessWidget {
  final Widget child;
  const BaseLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Define Breakpoint
        bool isDesktop = constraints.maxWidth >= 800;

        return Scaffold(
          // MOBILE: Add Drawer if screen is small
          drawer: !isDesktop ? const Drawer(child: SideMenu()) : null,
          
          appBar: !isDesktop
              ? AppBar(
                  title: const Text("ClockInn Admin"),
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  elevation: 2,
                )
              : null,
              
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // DESKTOP: Show Sidebar permanently
              if (isDesktop) const SizedBox(width: 250, child: SideMenu()),

              // MAIN CONTENT
              Expanded(
                child: Container(
                  color: const Color(0xFFF3F4F6),
                  child: Column(
                    children: [
                      // DESKTOP: Top Header (Hidden on Mobile since we have AppBar)
                      if (isDesktop)
                        Container(
                          height: 60,
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Admin Portal",
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  child: Icon(Icons.person, color: Colors.white)),
                            ],
                          ),
                        ),
                      
                      // Page Content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: child,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}