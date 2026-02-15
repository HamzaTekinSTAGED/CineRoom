import 'package:flutter/material.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {


  // there isnot any api which shows movie news
  // so i will use static news
  final List<Map<String, dynamic>> staticNews = [
    {
      "description": "Burt, the reptilian star of 1980s classic 'Crocodile Dundee,' has died at the age of at least 90 years old.The croc's death was announced by Australian reptile park Crocosaurus Cove, where Burt lived out his final years.'It is with great sadness that we announce the passing of Burt, the iconic Saltwater crocodile and star of the Australian classic Crocodile Dundee,' the attraction wrote in an Instagram post...",
      "image": "https://m.media-amazon.com/images/M/MV5BMzc4MmJjMzYtY2ZmZC00MTQwLWExYmMtMjlmN2Y1NGVkZjhhXkEyXkFqcGc@._V1_QL75_UX500_CR0,26,500,281_.jpg",
      "title": "Burt, Reptilian Star of 'Crocodile Dundee,' Dies at More Than 90 Years Old"
    },
    {
      "description": "'My Hero Academia' spinoff series 'My Hero Academia: Vigilantes' is set to premiere in Japan in April 2025, as the original anime takes its final bow.Toho Animation unveiled the adaptation of 'My Hero Academia: Vigilantes,' which is based on the manga series of the same name, during Jump Festa 2025 on Saturday...",
      "image": "https://m.media-amazon.com/images/M/MV5BMjA3NDE4NGItMDU1MC00MmY3LTk3M2EtNDA1ODVjMTczOTkwXkEyXkFqcGc@._V1_QL75_UX500_CR0,0,500,281_.jpg",
      "title": "'My Hero Academia: Vigilantes' Spinoff Series to Premiere in April 2025"
    },
    {
      "description": "Updated: 'Sonic the Hedgehog 3' has powered to the top of box office charts while 'Mufasa: The Lion King' is getting trampled in its first weekend of release.Paramount's third 'Sonic' adventure has opened at No. 1 with \$60 million from 3,761 North American theaters...",
      "image": "https://m.media-amazon.com/images/M/MV5BYTU4ZTkzMmYtZTRmYi00YzBlLTk5MDAtYTNkY2JiOTJlODkyXkEyXkFqcGc@._V1_QL75_UY281_CR86,0,500,281_.jpg",
      "title": "Box Office: 'Sonic 3' Speeds to \$60 Million Debut, 'Mufasa: The Lion King' Gets Trampled With \$35 Million"
    },
    {
      "description": "'Doctor Who' producer Bad Wolf has increased its profits by 49% despite a drop in revenue year-on-year.Post-tax profits rose from £7,072,610 (\$8.9 million) in 2023 to £10,554,620 (\$13.2 million) in 2024, latest records show...",
      "image": "https://m.media-amazon.com/images/M/MV5BMGU5ZWViMTMtMWRkMi00NjJmLThlMTctN2FlYzU4NDQyN2Q2XkEyXkFqcGc@._V1_QL75_UX500_CR0,26,500,281_.jpg",
      "title": "'Doctor Who' Producer Bad Wolf's Profits Climb to \$13 Million Despite Drop in Revenue"
    },
    {
      "description": "Sales company Lightdox has boarded Igor Bezinović's hybrid documentary 'Fiume o morte!,' which premieres in the Tiger Competition section of the International Film Festival Rotterdam...",
      "image": "https://m.media-amazon.com/images/M/MV5BN2YyZGM1ZmYtYmY2OC00MWFhLTlmZjAtYzRhNzAzNjcxYWY3XkEyXkFqcGc@._V1_QL75_UX500_CR0,26,500,281_.jpg",
      "title": "Lightdox Boards Rotterdam Tiger Competition Entry 'Fiume O Morte!,' About Italian Nationalist Poet Gabriele D'Annunzio (Exclusive)"
    },
    {
      "description": "Bollywood star Varun Dhawan is embracing the larger-than-life cinema style of South India with his upcoming Christmas release 'Baby John,' a film that had him studying the iconic mannerisms of superstar Rajinikanth in preparation for his role...",
      "image": "https://m.media-amazon.com/images/M/MV5BZTRlMDY4NzctMTQ1MS00MTM3LWJjMzMtMzI3YzI5ODY1ZjEyXkEyXkFqcGc@._V1_QL75_UX500_CR0,26,500,281_.jpg",
      "title": "Varun Dhawan Channels Rajinikanth in Christmas Release 'Baby John': 'I Wanted to be That Macho Hero'"
    },
    {
      "description": "'It Ends With Us' actor Brandon Sklenar has supported his co-star Blake Lively after she accused their fellow actor and director Justin Baldoni of sexual harassment and a smear campaign...",
      "image": "https://m.media-amazon.com/images/M/MV5BMzFhN2FhOWMtYmQzNS00YjkwLTliNmMtZDY5ZDQ2Njg4OWZhXkEyXkFqcGc@._V1_QL75_UX500_CR0,26,500,281_.jpg",
      "title": "'It Ends With Us' Star Brandon Sklenar Posts Blake Lively's Complaint Against Justin Baldoni: 'For the Love of God Read This'"
    },
    {
      "description": "Nicholas Hoult revealed what item from the Nosferatu set he has at home — but he didn't take it himself...",
      "image": "https://m.media-amazon.com/images/M/MV5BMDQyZGZhNTAtYWMyMS00ZmUwLWFjOWItMjgzMDc2N2Y3NzQ2XkEyXkFqcGc@._V1_QL75_UX140_CR0,0,140,140_.jpg",
      "title": "Nicholas Hoult Has Bill Skarsgard's Prosthetic Penis From 'Nosferatu' 'Framed at Home'"
    },
    {
      "description": "Can animals act? Sensible people would say not: Our four-legged friends can't read a script or construct a character, and if they come across charismatically on screen, that's simply down to obeying commands, plus the deft touch of an editor...",
      "image": "https://m.media-amazon.com/images/M/MV5BODJhZTc2NGQtZWFhZi00MzIxLTg0YjItYmU5MzM1NTEzODI5XkEyXkFqcGc@._V1_QL75_UX500_CR0,26,500,281_.jpg",
      "title": "'Dog on Trial' Review: A Movie-Star Mutt Bounds Off With This Canine Courtroom Comedy"
    },
    {
      "description": "Spoiler Alert: This article contains major spoilers from Season 2, Episode 8 of 'Bad Sisters,' now streaming on Apple TV+.Trust 'Bad Sisters' showrunner and actor Sharon Horgan to finish the second season of the hit Apple TV+ series with a literal cliffhanger...",
      "image": "https://m.media-amazon.com/images/M/MV5BYTQ0YWE1YzAtYjllZS00ZTM3LWI1ZWEtYTY2ODQ5ZTgxZGYyXkEyXkFqcGc@._V1_QL75_UX500_CR0,26,500,281_.jpg",
      "title": "'Bad Sisters' Cast Break Down the (Literal) Cliffhanger Season Finale, Plans for Season 3 and Ian's Fate"
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Movie News',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh logic can be added here
        },
        child: _buildNewsList(staticNews),
      ),
    );
  }

  Widget _buildNewsList(List<Map<String, dynamic>> newsList) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      physics: const BouncingScrollPhysics(),
      itemCount: newsList.length,
      itemBuilder: (context, index) {
        final news = newsList[index];
        return GestureDetector(
          onTap: () => _showNewsDetail(context, news),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset:const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:const BorderRadius.vertical(top: Radius.circular(12.0)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      news['image'] ?? news['posterUrl'] ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.error, size: 40, color: Colors.grey[600]),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        news['title'] ?? news['newsTitle'] ?? '',
                        style:const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        news['description'] ?? '',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style:const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Read More',
                            style: TextStyle(
                              color: Colors.deepPurple[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.deepPurple[700],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNewsDetail(BuildContext context, Map<String, dynamic> news) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        news['image'] ?? news['posterUrl'] ?? '',
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: Icon(Icons.error, size: 40, color: Colors.grey[600]),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      news['title'] ?? news['newsTitle'] ?? '',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      news['description'] ?? '',
                      style:const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.6,
                      ),
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
}
