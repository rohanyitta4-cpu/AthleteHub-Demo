import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import '../widgets/silver_accent_container.dart';
import '../utils/friendly_error.dart';

class PersonalizationScreen extends StatefulWidget {
  const PersonalizationScreen({super.key});

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends State<PersonalizationScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _jerseyNumberController = TextEditingController();
  final _teamNameController = TextEditingController();
  final _motivationalQuoteController = TextEditingController();
  final _favoritePlayerController = TextEditingController();
  
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isSaving = false;
  File? _selectedImage;
  String? _profilePictureUrl;
  
  // Preferences
  String _selectedTheme = 'light';
  bool _notificationsEnabled = true;
  String _defaultChartType = 'line';
  List<String> _favoriteStats = ['points', 'rebounds', 'assists'];
  
  // Player Identity
  String? _selectedAvatar;
  List<String> _selectedPositions = [];
  String? _batHand;
  String? _throwHand;
  String? _favoriteMLBTeam;
  String? _customBackgroundColor;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _jerseyNumberController.dispose();
    _teamNameController.dispose();
    _motivationalQuoteController.dispose();
    _favoritePlayerController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    
    final profile = await UserProfileService.getCurrentUserProfile();
    if (profile != null) {
      setState(() {
        _userProfile = profile;
        _displayNameController.text = profile.displayName;
        _bioController.text = profile.bio ?? '';
        _jerseyNumberController.text = profile.jerseyNumber ?? '';
        _teamNameController.text = profile.teamName ?? '';
        _motivationalQuoteController.text = profile.motivationalQuote ?? '';
        _favoritePlayerController.text = profile.favoriteMLBPlayer ?? '';
        _profilePictureUrl = profile.profilePictureUrl;
        _selectedTheme = profile.preferences['theme'] ?? 'light';
        _notificationsEnabled = profile.preferences['notifications'] ?? true;
        _defaultChartType = profile.preferences['defaultChartType'] ?? 'line';
        _favoriteStats = List<String>.from(profile.favoriteStats);
        _selectedAvatar = profile.selectedAvatar;
        _selectedPositions = List<String>.from(profile.positions);
        _batHand = profile.batHand;
        _throwHand = profile.throwHand;
        _favoriteMLBTeam = profile.favoriteMLBTeam;
        _customBackgroundColor = profile.customBackgroundColor;
      });
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      String? imageUrl = _profilePictureUrl;
      
      // Upload new profile picture if selected
      if (_selectedImage != null && _userProfile != null) {
        final uploadedUrl = await UserProfileService.uploadProfilePicture(
          _selectedImage!,
          _userProfile!.uid,
        );
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }
      
      // Update profile
      if (_userProfile != null) {
        final updatedProfile = _userProfile!.copyWith(
          displayName: _displayNameController.text.trim(),
          bio: _bioController.text.trim(),
          profilePictureUrl: imageUrl,
          jerseyNumber: _jerseyNumberController.text.trim(),
          teamName: _teamNameController.text.trim(),
          motivationalQuote: _motivationalQuoteController.text.trim(),
          favoriteMLBPlayer: _favoritePlayerController.text.trim(),
          updatedAt: DateTime.now(),
          preferences: {
            'theme': _selectedTheme,
            'notifications': _notificationsEnabled,
            'defaultChartType': _defaultChartType,
          },
          favoriteStats: _favoriteStats,
          selectedAvatar: _selectedAvatar,
          positions: _selectedPositions,
          batHand: _batHand,
          throwHand: _throwHand,
          favoriteMLBTeam: _favoriteMLBTeam,
          customBackgroundColor: _customBackgroundColor,
        );
        
        final success = await UserProfileService.saveUserProfile(updatedProfile);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update profile. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, "Couldn't update your profile")),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Account Settings', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Account Settings', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Profile', icon: Icon(Icons.person)),
            Tab(text: 'Player Info', icon: Icon(Icons.sports_baseball)),
            Tab(text: 'Customization', icon: Icon(Icons.palette)),
            Tab(text: 'Preferences', icon: Icon(Icons.settings)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text('Save', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildProfileTab(),
            _buildPlayerInfoTab(),
            _buildCustomizationTab(),
            _buildPreferencesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Picture Section
          _buildProfilePictureSection(),
          const SizedBox(height: 24),
          
          // Basic Information
          _buildBasicInfoSection(),
          const SizedBox(height: 24),
          
          // Achievement Badges
          _buildAchievementBadgesSection(),
        ],
      ),
    );
  }

  Widget _buildPlayerInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Jersey Number & Team
          _buildJerseyTeamSection(),
          const SizedBox(height: 24),
          
          // Position Selection
          _buildPositionSection(),
          const SizedBox(height: 24),
          
          // Bat/Throw Hand
          _buildHandednessSection(),
          const SizedBox(height: 24),
          
          // MLB Favorites
          _buildMLBFavoritesSection(),
        ],
      ),
    );
  }

  Widget _buildCustomizationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar Selection
          _buildAvatarSelectionSection(),
          const SizedBox(height: 24),
          
          // Custom Background
          _buildCustomBackgroundSection(),
          const SizedBox(height: 24),
          
          // Motivational Quote
          _buildMotivationalQuoteSection(),
        ],
      ),
    );
  }

  Widget _buildPreferencesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Theme Selection
          _buildThemeSection(),
          const SizedBox(height: 24),
          
          // Notifications
          _buildNotificationsSection(),
          const SizedBox(height: 24),
          
          // Chart Preferences
          _buildChartPreferencesSection(),
          const SizedBox(height: 24),
          
          // Favorite Stats
          _buildFavoriteStatsSection(),
        ],
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return SilverAccentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Picture',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  image: _selectedImage != null
                      ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        )
                      : _profilePictureUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_profilePictureUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                ),
                child: _selectedImage == null && _profilePictureUrl == null
                    ? Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.grey.shade400,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt, size: 16),
              label: const Text('Change Photo'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return SilverAccentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _displayNameController,
            decoration: const InputDecoration(
              labelText: 'Display Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a display name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bioController,
            decoration: const InputDecoration(
              labelText: 'Bio (Optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadgesSection() {
    final badges = [
      {'name': 'First Hit', 'earned': true, 'icon': Icons.sports_baseball},
      {'name': '10 Hits', 'earned': true, 'icon': Icons.star},
      {'name': 'First Home Run', 'earned': false, 'icon': Icons.emoji_events},
      {'name': 'Perfect Game', 'earned': false, 'icon': Icons.workspace_premium},
    ];

    return SilverAccentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Achievement Badges',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Earned badges for milestones',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: badges.map((badge) {
              final isEarned = badge['earned'] as bool;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEarned ? Colors.green.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isEarned ? Colors.green : Colors.grey,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      badge['icon'] as IconData,
                      color: isEarned ? Colors.green : Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      badge['name'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isEarned ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildJerseyTeamSection() {
    return SilverAccentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jersey & Team',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _jerseyNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Jersey Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.tag),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _teamNameController,
                  decoration: const InputDecoration(
                    labelText: 'Team Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.groups),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPositionSection() {
    final positions = [
      'Pitcher', 'Catcher', 'First Base', 'Second Base', 'Third Base',
      'Shortstop', 'Left Field', 'Center Field', 'Right Field', 'Designated Hitter'
    ];

    return SilverAccentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Position(s)',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your primary and secondary positions',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: positions.map((position) {
              final isSelected = _selectedPositions.contains(position);
              return FilterChip(
                label: Text(position),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedPositions.add(position);
                    } else {
                      _selectedPositions.remove(position);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHandednessSection() {
    return SilverAccentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bat/Throw Hand',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bat Hand', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Right'),
                            value: 'right',
                            groupValue: _batHand,
                            onChanged: (value) => setState(() => _batHand = value),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Left'),
                            value: 'left',
                            groupValue: _batHand,
                            onChanged: (value) => setState(() => _batHand = value),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Throw Hand', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Right'),
                            value: 'right',
                            groupValue: _throwHand,
                            onChanged: (value) => setState(() => _throwHand = value),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Left'),
                            value: 'left',
                            groupValue: _throwHand,
                            onChanged: (value) => setState(() => _throwHand = value),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMLBFavoritesSection() {
    final mlbTeams = [
      'Yankees', 'Red Sox', 'Dodgers', 'Giants', 'Cubs', 'Cardinals',
      'Braves', 'Phillies', 'Mets', 'Nationals', 'Marlins', 'Rays',
      'Blue Jays', 'Orioles', 'Indians', 'Tigers', 'White Sox', 'Twins',
      'Royals', 'Astros', 'Rangers', 'Angels', 'Athletics', 'Mariners'
    ];

    return SilverAccentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MLB Favorites',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _favoriteMLBTeam,
            decoration: const InputDecoration(
              labelText: 'Favorite MLB Team',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.sports_baseball),
            ),
            items: [
              const DropdownMenuItem<String>(value: null, child: Text('Select Team')),
              ...mlbTeams.map((team) => DropdownMenuItem(value: team, child: Text(team))),
            ],
            onChanged: (value) => setState(() => _favoriteMLBTeam = value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _favoritePlayerController,
            decoration: const InputDecoration(
              labelText: 'Favorite MLB Player',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSelectionSection() {
    final avatars = [
      {'name': 'Baseball Glove', 'icon': Icons.sports_baseball},
      {'name': 'Baseball Bat', 'icon': Icons.sports},
      {'name': 'Baseball Cap', 'icon': Icons.sports_motorsports},
      {'name': 'Trophy', 'icon': Icons.emoji_events},
    ];

    return SilverAccentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Baseball-Themed Avatars',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a baseball-themed avatar as an alternative to your photo',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: avatars.map((avatar) {
              final isSelected = _selectedAvatar == avatar['name'];
              return GestureDetector(
                onTap: () => setState(() => _selectedAvatar = avatar['name'] as String),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        avatar['icon'] as IconData,
                        color: isSelected ? Colors.blue : Colors.grey,
                        size: 32,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        avatar['name'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isSelected ? Colors.blue : Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomBackgroundSection() {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    return SilverAccentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Custom Background',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a color theme for your profile background',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: colors.map((color) {
              final colorValue = '#${color.value.toRadixString(16).substring(2)}';
              final isSelected = _customBackgroundColor == colorValue;
              return GestureDetector(
                onTap: () => setState(() => _customBackgroundColor = colorValue),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.grey,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 24,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationalQuoteSection() {
    return SilverAccentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Motivational Quote',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a motivational quote or bio to your profile',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _motivationalQuoteController,
            decoration: const InputDecoration(
              labelText: 'Quote or Bio',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.format_quote),
              hintText: 'e.g., "Baseball is 90% mental and the other half is physical." - Yogi Berra',
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection() {
    return SilverAccentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Light'),
                  value: 'light',
                  groupValue: _selectedTheme,
                  onChanged: (value) => setState(() => _selectedTheme = value!),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Dark'),
                  value: 'dark',
                  groupValue: _selectedTheme,
                  onChanged: (value) => setState(() => _selectedTheme = value!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return SilverAccentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive updates about your stats and games'),
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
          ),
        ],
      ),
    );
  }

  Widget _buildChartPreferencesSection() {
    return SilverAccentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chart Preferences',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _defaultChartType,
            decoration: const InputDecoration(
              labelText: 'Default Chart Type',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.bar_chart),
            ),
            items: const [
              DropdownMenuItem(value: 'line', child: Text('Line Chart')),
              DropdownMenuItem(value: 'bar', child: Text('Bar Chart')),
              DropdownMenuItem(value: 'area', child: Text('Area Chart')),
            ],
            onChanged: (value) => setState(() => _defaultChartType = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteStatsSection() {
    final availableStats = [
      'points', 'rebounds', 'assists', 'steals', 'blocks', 'turnovers',
      'fieldGoalsMade', 'fieldGoalsAttempted', 'threePointersMade', 'threePointersAttempted',
      'freeThrowsMade', 'freeThrowsAttempted'
    ];

    return SilverAccentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Favorite Stats',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your most important stats to display on the dashboard',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableStats.map((stat) {
              final isSelected = _favoriteStats.contains(stat);
              return FilterChip(
                label: Text(_convertToProperCase(stat)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _favoriteStats.add(stat);
                    } else {
                      _favoriteStats.remove(stat);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _convertToProperCase(String text) {
    return text.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    ).split(' ').map((word) => word.isNotEmpty 
        ? word[0].toUpperCase() + word.substring(1).toLowerCase()
        : word
    ).join(' ');
  }
}