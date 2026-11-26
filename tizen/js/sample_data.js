/* Pure ES5 Sample Film & Movie Dataset for YumiHub Samsung TV */
(function (root) {
  'use strict';

  function makePosterSvg(title, sub, c1, c2, badge) {
    var safeTitle = String(title).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    var safeSub = String(sub).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    var svg =
      '<svg xmlns="http://www.w3.org/2000/svg" width="400" height="600" viewBox="0 0 400 600">' +
      '<defs>' +
      '<linearGradient id="g" x1="0" y1="0" x2="1" y2="1">' +
      '<stop offset="0%" stop-color="' + c1 + '"/>' +
      '<stop offset="100%" stop-color="' + c2 + '"/>' +
      '</linearGradient>' +
      '</defs>' +
      '<rect width="400" height="600" fill="url(#g)"/>' +
      '<circle cx="310" cy="120" r="140" fill="rgba(255,255,255,0.10)"/>' +
      '<circle cx="90" cy="460" r="170" fill="rgba(0,0,0,0.22)"/>' +
      '<rect x="28" y="34" width="132" height="34" rx="17" fill="rgba(11,16,36,0.72)"/>' +
      '<text x="94" y="56" font-family="Arial,sans-serif" font-size="15" font-weight="bold" fill="#FFFFFF" text-anchor="middle">' + badge + '</text>' +
      '<polygon points="172,225 172,305 242,265" fill="rgba(255,255,255,0.9)"/>' +
      '<circle cx="200" cy="265" r="66" fill="none" stroke="rgba(255,255,255,0.55)" stroke-width="5"/>' +
      '<rect x="24" y="388" width="352" height="162" rx="16" fill="rgba(11,16,36,0.78)"/>' +
      '<text x="44" y="438" font-family="Arial,sans-serif" font-size="24" font-weight="bold" fill="#FFFFFF">' + safeTitle + '</text>' +
      '<text x="44" y="476" font-family="Arial,sans-serif" font-size="16" fill="#A3A5B8">' + safeSub + '</text>' +
      '<text x="44" y="518" font-family="Arial,sans-serif" font-size="14" font-weight="bold" fill="#4FA3FF">YUMIHUB FILM &amp; MOVIE</text>' +
      '</svg>';
    return 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(svg);
  }

  function createSampleBackupPayload() {
    var now = Date.now();
    return {
      version: '2',
      categories: [
        { id: 101, name: 'Viễn tưởng & Phiêu lưu', forItemType: 1, pos: 0, hide: false },
        { id: 102, name: 'Hoạt hình Gia đình', forItemType: 1, pos: 1, hide: false },
        { id: 103, name: 'Phim Tài liệu', forItemType: 1, pos: 2, hide: false },
        { id: 901, name: 'Danh mục loại 0 (bị lọc bỏ)', forItemType: 0, pos: 0, hide: false }
      ],
      manga: [
        {
          id: 1,
          name: 'Biên Niên Sử Tinh Vân',
          author: 'Studio Ánh Sáng',
          artist: 'Đạo diễn Minh Quân',
          status: 0,
          itemType: 1,
          favorite: true,
          source: 'YumiHub Demo',
          lang: 'vi',
          genre: ['Khoa học viễn tưởng', 'Phiêu lưu'],
          categories: [101],
          imageUrl: makePosterSvg('Biên Niên Sử Tinh Vân', 'Studio Ánh Sáng · 2026', '#16285A', '#4B1F6F', '4K UHD'),
          description: 'Chuyến du hành vượt qua vành đai sao băng ngoài rìa thiên hà của phi hành đoàn tàu trinh sát bình minh.',
          lastUpdate: now - 1200000,
          updatedAt: now - 1200000
        },
        {
          id: 2,
          name: 'Hành Trình Qua Rừng Đêm',
          author: 'Xưởng Phim Mùa Thu',
          artist: 'Đạo diễn Hải An',
          status: 1,
          itemType: 1,
          favorite: true,
          source: 'YumiHub Demo',
          lang: 'vi',
          genre: ['Hoạt hình', 'Gia đình'],
          categories: [102],
          imageUrl: makePosterSvg('Hành Trình Rừng Đêm', 'Xưởng Phim Mùa Thu', '#0E3B43', '#1E5B4C', 'FULL HD'),
          description: 'Câu chuyện ấm áp về hai anh em đi tìm chiếc đèn lồng cổ bị thất lạc giữa khu rừng đom đóm.',
          lastUpdate: now - 3600000,
          updatedAt: now - 3600000
        },
        {
          id: 3,
          name: 'Nhịp Đập Thành Phố 2088',
          author: 'Horizon Pictures',
          artist: 'Đạo diễn Lan Vy',
          status: 0,
          itemType: 1,
          favorite: true,
          source: 'YumiHub Demo',
          lang: 'vi',
          genre: ['Hành động', 'Khoa học viễn tưởng'],
          categories: [101],
          imageUrl: makePosterSvg('Thành Phố 2088', 'Horizon Pictures', '#2B1B54', '#75255B', 'HDR10+'),
          description: 'Giữa đô thị nổi rực rỡ ánh đèn neon, một kỹ sư âm thanh trẻ phát hiện tín hiệu bí ẩn từ tầng mây dưới.',
          lastUpdate: now - 7200000,
          updatedAt: now - 7200000
        },
        {
          id: 4,
          name: 'Khúc Ca Biển Sâu',
          author: 'Đại Dương Xanh',
          artist: 'Đạo diễn Trọng Nghĩa',
          status: 1,
          itemType: 1,
          favorite: true,
          source: 'YumiHub Demo',
          lang: 'vi',
          genre: ['Tài liệu', 'Thiên nhiên'],
          categories: [103],
          imageUrl: makePosterSvg('Khúc Ca Biển Sâu', 'Phim Tài Liệu Biển', '#0B2F52', '#0D5E68', '4K DOC'),
          description: 'Ghi lại hành trình di cư hàng nghìn hải lý của các loài sinh vật đại dương qua góc máy siêu chậm.',
          lastUpdate: now - 14400000,
          updatedAt: now - 14400000
        },
        {
          id: 5,
          name: 'Bầu Trời Mùa Hạ',
          author: 'Xưởng Phim Gió Nam',
          artist: 'Đạo diễn Thu Hà',
          status: 1,
          itemType: 1,
          favorite: true,
          source: 'YumiHub Demo',
          lang: 'vi',
          genre: ['Hoạt hình', 'Đời thường'],
          categories: [102],
          imageUrl: makePosterSvg('Bầu Trời Mùa Hạ', 'Xưởng Phim Gió Nam', '#1F3A70', '#8C3E67', 'HD 1080p'),
          description: 'Mùa hè đáng nhớ của nhóm bạn nhỏ cùng nhau dựng chiếc máy bay giấy khổng lồ trên ngọn đồi lộng gió.',
          lastUpdate: now - 28800000,
          updatedAt: now - 28800000
        },
        {
          id: 6,
          name: 'Người Giữ Ngọn Hải Đăng',
          author: 'Bến Cảng Studio',
          artist: 'Đạo diễn Quốc Bảo',
          status: 0,
          itemType: 1,
          favorite: true,
          source: 'YumiHub Demo',
          lang: 'vi',
          genre: ['Chính kịch', 'Phiêu lưu'],
          categories: [101, 103],
          imageUrl: makePosterSvg('Ngọn Hải Đăng', 'Bến Cảng Studio', '#1D243C', '#46325C', 'SERIES'),
          description: 'Những đêm bão tố ngoài khơi xa và câu chuyện về người thợ giữ ánh sáng cho những con tàu trở về.',
          lastUpdate: now - 43200000,
          updatedAt: now - 43200000
        },
        {
          id: 999,
          name: 'Mục dữ liệu khác (không phải Phim)',
          author: 'Test Filter',
          status: 0,
          itemType: 0,
          favorite: true,
          source: 'Other',
          lang: 'vi',
          genre: [],
          categories: [901],
          imageUrl: '',
          description: 'Dữ liệu thử nghiệm để kiểm tra bộ lọc itemType === 1.'
        }
      ],
      chapters: [
        { id: 1001, mangaId: 1, name: 'Tập 1: Khởi hành từ trạm quỹ đạo', url: 'assets/sample_trailer.webm', dateUpload: String(now - 1200000), duration: '00:10', isRead: false, lastPageRead: '4' },
        { id: 1002, mangaId: 1, name: 'Tập 2: Tín hiệu ngoài rìa tinh vân', url: 'assets/sample_trailer.webm', dateUpload: String(now - 900000), duration: '00:10', isRead: false, lastPageRead: '0' },
        { id: 1003, mangaId: 1, name: 'Tập 3: Vượt qua vành đai băng', url: 'assets/sample_trailer.webm', dateUpload: String(now - 600000), duration: '00:10', isRead: false, lastPageRead: '0' },
        { id: 2001, mangaId: 2, name: 'Tập 1: Cánh cổng đom đóm', url: 'assets/sample_trailer.webm', dateUpload: String(now - 3600000), duration: '00:10', isRead: true, lastPageRead: '10' },
        { id: 2002, mangaId: 2, name: 'Tập 2: Chiếc đèn lồng ký ức', url: 'assets/sample_trailer.webm', dateUpload: String(now - 3000000), duration: '00:10', isRead: false, lastPageRead: '3' },
        { id: 3001, mangaId: 3, name: 'Tập 1: Tần số tầng mây', url: 'assets/sample_trailer.webm', dateUpload: String(now - 7200000), duration: '00:10', isRead: false, lastPageRead: '0' },
        { id: 3002, mangaId: 3, name: 'Tập 2: Khu phố không ngủ', url: 'assets/sample_trailer.webm', dateUpload: String(now - 7000000), duration: '00:10', isRead: false, lastPageRead: '0' },
        { id: 4001, mangaId: 4, name: 'Phần 1: Dòng hải lưu phương Nam', url: 'assets/sample_trailer.webm', dateUpload: String(now - 14400000), duration: '00:10', isRead: false, lastPageRead: '0' },
        { id: 5001, mangaId: 5, name: 'Bản điện ảnh đầy đủ', url: 'assets/sample_trailer.webm', dateUpload: String(now - 28800000), duration: '00:10', isRead: true, lastPageRead: '10' },
        { id: 6001, mangaId: 6, name: 'Tập 1: Ánh sáng giữa biển khơi', url: 'assets/sample_trailer.webm', dateUpload: String(now - 43200000), duration: '00:10', isRead: false, lastPageRead: '0' },
        { id: 9991, mangaId: 999, name: 'Tập lọc bỏ', url: 'assets/sample_trailer.webm', dateUpload: String(now), duration: '00:10', isRead: false, lastPageRead: '0' }
      ],
      history: [
        { id: 501, itemType: 1, mangaId: 1, chapterId: 1001, date: String(now - 500000), readingTimeSeconds: 4 },
        { id: 502, itemType: 1, mangaId: 2, chapterId: 2002, date: String(now - 1500000), readingTimeSeconds: 3 }
      ]
    };
  }

  function getBrowseCatalog() {
    return [
      {
        id: 701,
        name: 'Vùng Đất Tuyết Trắng',
        author: 'Nordic Animation',
        status: 1,
        itemType: 1,
        source: 'Danh mục TV đề xuất',
        genre: ['Hoạt hình', 'Phiêu lưu'],
        imageUrl: makePosterSvg('Vùng Đất Tuyết', 'Nordic Animation', '#163459', '#31658F', 'MỚI'),
        description: 'Cuộc phiêu lưu băng qua dãy núi tuyết vĩnh cửu để bảo vệ đàn tuần lộc phương Bắc.',
        episodes: [
          { id: 7011, mangaId: 701, name: 'Phim đầy đủ (Demo Stream)', url: 'assets/sample_trailer.webm', duration: '00:10' }
        ]
      },
      {
        id: 702,
        name: 'Đường Đua Ánh Sáng',
        author: 'Velocity Film',
        status: 0,
        itemType: 1,
        source: 'Danh mục TV đề xuất',
        genre: ['Hành động', 'Thể thao'],
        imageUrl: makePosterSvg('Đường Đua Ánh Sáng', 'Velocity Film', '#3C1B59', '#912D56', '60FPS'),
        description: 'Giải đua mô tô năng lượng sạch xuyên qua các cung đường ven biển ban đêm.',
        episodes: [
          { id: 7021, mangaId: 702, name: 'Tập 1: Vòng loại đêm mưa', url: 'assets/sample_trailer.webm', duration: '00:10' },
          { id: 7022, mangaId: 702, name: 'Tập 2: Chặng chung kết', url: 'assets/sample_trailer.webm', duration: '00:10' }
        ]
      },
      {
        id: 703,
        name: 'Bí Ẩn Thung Lũng Đá',
        author: 'Cửu Long Pictures',
        status: 1,
        itemType: 1,
        source: 'Danh mục TV đề xuất',
        genre: ['Tài liệu', 'Khám phá'],
        imageUrl: makePosterSvg('Thung Lũng Đá', 'Cửu Long Pictures', '#1A3E36', '#335E45', '4K'),
        description: 'Phóng sự khám phá hệ thống hang động đá vôi cổ đại và hệ sinh thái nguyên sinh.',
        episodes: [
          { id: 7031, mangaId: 703, name: 'Phần 1: Lòng đất sâu', url: 'assets/sample_trailer.webm', duration: '00:10' }
        ]
      },
      {
        id: 704,
        name: 'Chuyến Tàu Hoàng Hôn',
        author: 'Ký Ức Studio',
        status: 1,
        itemType: 1,
        source: 'Danh mục TV đề xuất',
        genre: ['Chính kịch', 'Gia đình'],
        imageUrl: makePosterSvg('Tàu Hoàng Hôn', 'Ký Ức Studio', '#4A253F', '#8F4C39', 'HD'),
        description: 'Những cuộc gặp gỡ bất ngờ trên chuyến tàu đường dài xuyên qua những miền quê yên bình.',
        episodes: [
          { id: 7041, mangaId: 704, name: 'Tập đặc biệt', url: 'assets/sample_trailer.webm', duration: '00:10' }
        ]
      },
      {
        id: 705,
        name: 'Vệ Tinh Số 9',
        author: 'Cosmos Lab',
        status: 0,
        itemType: 1,
        source: 'Danh mục TV đề xuất',
        genre: ['Khoa học viễn tưởng', 'Tài liệu'],
        imageUrl: makePosterSvg('Vệ Tinh Số 9', 'Cosmos Lab', '#0C1E3E', '#2A3F7A', 'UHD'),
        description: 'Câu chuyện hậu trường về những kỹ sư phóng vệ tinh quan sát khí hậu đầu tiên.',
        episodes: [
          { id: 7051, mangaId: 705, name: 'Tập 1: Đếm ngược', url: 'assets/sample_trailer.webm', duration: '00:10' }
        ]
      }
    ];
  }

  root.YumiSampleData = {
    makePosterSvg: makePosterSvg,
    createSampleBackupPayload: createSampleBackupPayload,
    getBrowseCatalog: getBrowseCatalog
  };
})(window);
