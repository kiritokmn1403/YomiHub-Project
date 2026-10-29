var BASE_URL = "https://animevn.net/";
(function ($, window, document, undefined) {
    var $window = $(window);
    $.fn.lazyload = function (options) {
        var elements = this;
        var $container;
        var settings = {
            threshold: 0,
            failure_limit: 0,
            event: "scroll",
            effect: "show",
            container: window,
            data_attribute: "original",
            skip_invisible: false,
            appear: null,
            load: null,
            placeholder: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsQAAA7EAZUrDhsAAAANSURBVBhXYzh8+PB/AAffA0nNPuCLAAAAAElFTkSuQmCC",
        };
        function update() {
            var counter = 0;
            elements.each(function () {
                var $this = $(this);
                if (settings.skip_invisible && !$this.is(":visible")) {
                    return;
                }
                if ($.abovethetop(this, settings) || $.leftofbegin(this, settings)) {
                } else if (!$.belowthefold(this, settings) && !$.rightoffold(this, settings)) {
                    $this.trigger("appear");
                    counter = 0;
                } else {
                    if (++counter > settings.failure_limit) {
                        return false;
                    }
                }
            });
        }
        if (options) {
            if (undefined !== options.failurelimit) {
                options.failure_limit = options.failurelimit;
                delete options.failurelimit;
            }
            if (undefined !== options.effectspeed) {
                options.effect_speed = options.effectspeed;
                delete options.effectspeed;
            }
            $.extend(settings, options);
        }
        $container = settings.container === undefined || settings.container === window ? $window : $(settings.container);
        if (0 === settings.event.indexOf("scroll")) {
            $container.bind(settings.event, function () {
                return update();
            });
        }
        this.each(function () {
            var self = this;
            var $self = $(self);
            self.loaded = false;
            if ($self.attr("src") === undefined || $self.attr("src") === false) {
                if ($self.is("img")) {
                    $self.attr("src", settings.placeholder);
                }
            }
            $self.one("appear", function () {
                if (!this.loaded) {
                    if (settings.appear) {
                        var elements_left = elements.length;
                        settings.appear.call(self, elements_left, settings);
                    }
                    $("<img />")
                        .bind("load", function () {
                            var original = $self.attr("data-" + settings.data_attribute);
                            $self.hide();
                            if ($self.is("img")) {
                                $self.attr("src", original);
                            } else {
                                $self.css("background-image", "url('" + original + "')");
                            }
                            $self[settings.effect](settings.effect_speed);
                            self.loaded = true;
                            var temp = $.grep(elements, function (element) {
                                return !element.loaded;
                            });
                            elements = $(temp);
                            if (settings.load) {
                                var elements_left = elements.length;
                                settings.load.call(self, elements_left, settings);
                            }
                        })
                        .attr("src", $self.attr("data-" + settings.data_attribute));
                }
            });
            if (0 !== settings.event.indexOf("scroll")) {
                $self.bind(settings.event, function () {
                    if (!self.loaded) {
                        $self.trigger("appear");
                    }
                });
            }
        });
        $window.bind("resize", function () {
            update();
        });
        if (/(?:iphone|ipod|ipad).*os 5/gi.test(navigator.appVersion)) {
            $window.bind("pageshow", function (event) {
                if (event.originalEvent && event.originalEvent.persisted) {
                    elements.each(function () {
                        $(this).trigger("appear");
                    });
                }
            });
        }
        $(document).ready(function () {
            update();
        });
        return this;
    };
    $.belowthefold = function (element, settings) {
        var fold;
        if (settings.container === undefined || settings.container === window) {
            fold = (window.innerHeight ? window.innerHeight : $window.height()) + $window.scrollTop();
        } else {
            fold = $(settings.container).offset().top + $(settings.container).height();
        }
        return fold <= $(element).offset().top - settings.threshold;
    };
    $.rightoffold = function (element, settings) {
        var fold;
        if (settings.container === undefined || settings.container === window) {
            fold = $window.width() + $window.scrollLeft();
        } else {
            fold = $(settings.container).offset().left + $(settings.container).width();
        }
        return fold <= $(element).offset().left - settings.threshold;
    };
    $.abovethetop = function (element, settings) {
        var fold;
        if (settings.container === undefined || settings.container === window) {
            fold = $window.scrollTop();
        } else {
            fold = $(settings.container).offset().top;
        }
        return fold >= $(element).offset().top + settings.threshold + $(element).height();
    };
    $.leftofbegin = function (element, settings) {
        var fold;
        if (settings.container === undefined || settings.container === window) {
            fold = $window.scrollLeft();
        } else {
            fold = $(settings.container).offset().left;
        }
        return fold >= $(element).offset().left + settings.threshold + $(element).width();
    };
    $.inviewport = function (element, settings) {
        return !$.rightoffold(element, settings) && !$.leftofbegin(element, settings) && !$.belowthefold(element, settings) && !$.abovethetop(element, settings);
    };
    $.extend($.expr[":"], {
        "below-the-fold": function (a) {
            return $.belowthefold(a, { threshold: 0 });
        },
        "above-the-top": function (a) {
            return !$.belowthefold(a, { threshold: 0 });
        },
        "right-of-screen": function (a) {
            return $.rightoffold(a, { threshold: 0 });
        },
        "left-of-screen": function (a) {
            return !$.rightoffold(a, { threshold: 0 });
        },
        "in-viewport": function (a) {
            return $.inviewport(a, { threshold: 0 });
        },
        "above-the-fold": function (a) {
            return !$.belowthefold(a, { threshold: 0 });
        },
        "right-of-fold": function (a) {
            return $.rightoffold(a, { threshold: 0 });
        },
        "left-of-fold": function (a) {
            return !$.rightoffold(a, { threshold: 0 });
        },
    });
})(jQuery, window, document);
if (typeof Application == "undefined") {
    Application = {
        run: function () {
            this.showHideBarChapter();
            this.showMenuMobile();
            this.loadChapter();
            this.visitedComics();
            this.lazyloadActive();
            this.scrollToTop();
            this.goToTop();
            this.searchManga();
        },

        scrollToTop: function () {
            $(window).scroll(function () {
                if ($(this).scrollTop() > 100) {
                    $("#scrollup").css("opacity", 1);
                } else {
                    $("#scrollup").css("opacity", 0);
                }
            });
        },
        goToTop: function () {
            $("#scrollup").on("click", function () {
                $("html, body").animate({ scrollTop: 0 }, 100);
            });
        },
        showMenuMobile: function () {
            if ($(".header-mobile").length) {
                $(".btn-menu-close").click(function () {
                    if ($("#gnb").hasClass("menu-open")) {
                        $("body").removeAttr("style");
                        $("#gnb").removeClass("menu-open");
                        $(".gnb-back").css({ visibility: "hidden", opacity: 0 });
                    }
                });
                $(".side_menu.btn-menu").on("click", function (e) {
                    $("#gnb").removeClass("menu-close").addClass("menu-open");
                    $(".gnb-back").css({ visibility: "visible", opacity: 1 });
                    $("body").css("overflow", "hidden");
                    e.stopPropagation();
                });
                $(".side_search").on("click", function () {
                    $("#fun_search").show();
                });
                $(".btn-txt-cancel-search").on("click", function () {
                    $("#fun_search").hide();
                });
            }
            if ($("#show-more-chapters").length) {
                $("#show-more-chapters").on("click", function () {
                    $(".ep-body").addClass("loaded");
                });
            }
        },
        showHideBarChapter: function () {
            var prevScroll = 0,
                curDir = "down",
                prevDir = "up",
                viewerFooter = $(".viewer-footer");
            if (viewerFooter.length) {
                $(window).scroll(function () {
                    if ($(this).scrollTop() >= prevScroll) {
                        curDir = "down";
                        if (curDir != prevDir) {
                            $(viewerFooter).stop();
                            $(viewerFooter).animate({ bottom: "-72px" }, 300);
                            prevDir = curDir;
                        }
                    } else {
                        curDir = "up";
                        if (curDir != prevDir) {
                            $(viewerFooter).stop();
                            $(viewerFooter).animate({ bottom: "0px" }, 300);
                            prevDir = curDir;
                        }
                    }
                    prevScroll = $(this).scrollTop();
                });
            }
        },
        loadChapter: function () {
            if ($(".chapter-nav").length) {
                var linkPrevChapter = $("#chap-list li.current").next().find("a").attr("href");
                var linkNextChapter = $("#chap-list li.current").prev().find("a").attr("href");
                $(".btn-chapter-prev").attr("href", linkPrevChapter);
                if (linkNextChapter === "undefined" || !linkNextChapter) {
                    $(".btn-chapter-next").addClass("disabled");
                } else {
                    $(".btn-chapter-next").attr("href", linkNextChapter);
                }
                $(".btn-list-chapter").on("click", function () {
                    $("#chapters").show();
                });
                $(".rd-sidebar .black-click").on("click", function () {
                    $("#chapters").hide();
                });
            }
        },
        visitedComics: function () {
            if ($(".chapter-nav").length && "undefined" != typeof Storage) {
                var comicId = $('input[name="comicsid"]').val();
                var comics = $(".breadcumbs div").eq(1).find("a");
                var chapter = $(".breadcumbs div").eq(2).find("a");
                var image = $('meta[itemprop="image"]').attr("content");
                if (comicId) {
                    if (comics && chapter && image) {
                        var items = { id: comicId, image: image, name: comics.find("span").html(), url: comics.attr("href"), chapterName: chapter.find("span").html(), chapterUrl: chapter.attr("href") };
                        if (void 0 !== localStorage["visited-comics"]) {
                            var A,
                                S = (A = JSON.parse(localStorage["visited-comics"]))
                                    .map(function (e) {
                                        return e.id;
                                    })
                                    .indexOf(comicId);
                            if ((S > -1 && A.splice(S, 1), A.push(items), A.length > 72)) for (C = 72; C < A.length; C++) A.shift();
                            localStorage["visited-comics"] = JSON.stringify(A);
                        } else {
                            (j = []).push(items), (localStorage["visited-comics"] = JSON.stringify(j));
                        }
                    }
                }
            }
            if ($(".visited-comics-page").length && "undefined" != typeof Storage) {
                if (void 0 !== localStorage["visited-comics"]) {
                    if ((A = JSON.parse(localStorage["visited-comics"])).length > 0) {
                        var html = ` <ul>`;
                        for (C = A.length - 1; C >= 0; C--) {
                            var T = A[C];
                            html += `<li>
                            <div class="visual">
                                <div class="hentai-cover">
                                <a href="${T.url}">
                                    <img src="${T.image}" alt="${T.name}" data-original="${T.image}" class="lazy"/>
                                </a>
                                </div>
                                <div class="main_text">
                                    <h3 class="title"><a href="${T.url}">${T.name}</a></h3>
                                    <div class="item-meta-bottom">
                                        <div class="item-total-views">
                                            <a href="${T.chapterUrl}" title="${T.chapterName}" class="type01">Continue  <i class="glyphicon glyphicon-chevron-right"></i> </a> 
                                        </div>
                                        <div class="item-total-pages">${T.chapterName}</div>
                                    </div>
                                </div>
                            </div>
                            </li>`;
                        }
                        html += `</ul></div>`;
                        $(".visited-comics-page").empty().append(html);
                    } else {
                        $(".visited-comics-page").html('<div class="notfound-comics">No history.</div>');
                    }
                } else {
                    $(".visited-comics-page").html('<p class="notfound-comics">Bạn chưa đọc truyện nào.</p>');
                }
            }
        },
        searchManga: function () {
            if ($("#srch-val").length > 0) {
                $("#srch-val").on("keyup", function (e) {
                    var rs = $("#search-result");
                    var keyword = $(this).val();
                    var kw = keyword.trim().toLowerCase();
                    kw.length < 1
                        ? $(rs).hide()
                        : kw.length >= 1 &&
                          ($(e).addClass("loading"),
                          $.ajax({
                              type: "POST",
                              cache: !0,
                              url: BASE_URL + "search/html/1",
                              data: { keyword: kw },
                              dataType: "html",
                              success: function (res) {
                                  $(e).removeClass("loading");
                                  $("#search-result").html("").html(res).show();
                              },
                          }));
                });
            }
            if ($("#txtSearch").length > 0) {
                $("#txtSearch").on("keyup", function (e) {
                    var rs = $("#result-manga");
                    var keyword = $(this).val();
                    var kw = keyword.trim().toLowerCase();
                    kw.length < 1
                        ? $(rs).hide()
                        : kw.length >= 1 &&
                          ($(e).addClass("loading"),
                          $.ajax({
                              type: "POST",
                              cache: !0,
                              url: BASE_URL + "search/html/1",
                              data: { keyword: kw },
                              dataType: "html",
                              success: function (res) {
                                  $(e).removeClass("loading");
                                  $("#result-manga").html("").html(res).show();
                              },
                          }));
                });
            }
            if ($("#btn-mbsearch").length > 0) {
                $("#btn-mbsearch").on("click", function (e) {
                    var keyword = $("#txtSearch").val();
                    var kw = keyword.trim().toLowerCase();
                    if (kw >= 3) {
                        window.location.href = BASE_URL+"search?keyword=" + kw;
                    }
                    return false;
                });
            }
        },
        lazyloadActive: function () {
            if ($("img.lazy").length) {
                $("img.lazy").lazyload({ effect: "fadeIn" });
            }
        },
    };
    Application.run();
}
