import 'package:flutter/material.dart';

class ContentJson {
  Content? content;

  ContentJson({this.content});

  ContentJson.fromJson(Map<String, dynamic> json) {
    content =
        json['content'] != null ? new Content.fromJson(json['content']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.content != null) {
      data['content'] = this.content?.toJson();
    }
    return data;
  }
}

class Content {
  Document? document;

  Content({this.document});

  Content.fromJson(Map<String, dynamic> json) {
    document = json['document'] != null
        ? new Document.fromJson(json['document'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.document != null) {
      data['document'] = this.document?.toJson();
    }
    return data;
  }
}

class Document {
  List<ChildrenDocument>? children;
  DocumentData? data;
  List<Bookmark>? bookmarks;

  Document({this.children, this.data, this.bookmarks});

  Document.fromJson(Map<String, dynamic> json) {
    if (json['children'] != null) {
      children = <ChildrenDocument>[];
      json['children'].forEach((v) {
        children?.add(new ChildrenDocument.fromJson(v));
      });
    }
    if (json['data'] != null) {
      data = DocumentData.fromJson(json["data"]);
    }
    if (json['bookmarks'] != null) {
      bookmarks = List<Bookmark>.from(
          json["bookmarks"].map((x) => Bookmark.fromJson(x)));
    } else {
      bookmarks = [];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.children != null) {
      data['children'] = this.children?.map((v) => v.toJson()).toList();
    }
    if (this.data != null) {
      data["data"] = this.data?.toJson();
    }
    if (this.bookmarks != null) {
      data['bookmarks'] =
          List<Bookmark>.from(this.bookmarks!.map((x) => x.toJson()));
    }
    return data;
  }
}

class DocumentData {
  DocumentData({
    this.version,
  });

  int? version;

  factory DocumentData.fromJson(Map<String, dynamic> json) => DocumentData(
        version: json["version"] != null
            ? int.parse(
                json["version"].toString().replaceAll(RegExp('[^0-9]'), ''))
            : 0,
      );

  Map<String, dynamic> toJson() => {
        "version": version,
      };
}

class Bookmark implements Comparable {
  Bookmark({this.stime, this.etime, this.id, this.text});

  int? stime;
  int? etime;
  String? id;
  String? text;

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        stime: json["stime"] ?? 0,
        etime: json["etime"] ?? 0,
        id: json["id"],
        text: '',
      );

  Map<String, dynamic> toJson() => {
        "stime": stime,
        "etime": etime,
        "id": id,
      };

   @override
   int compareTo(other) {
     if (this.stime == null || other == null) {
       throw UnimplementedError();
     }

     if (this.stime! < other.stime) {
       return 1;
     }

     if (this.stime! > other.stime) {
       return -1;
     }

     if (this.stime == other.stime) {
       return 0;
     }

     throw UnimplementedError();
   }
}

class ChildrenDocument {
  String? type;
  List<ChildrenContent>? children;

  /// List child's stime for highlight helper
  List<int>? childrenPositions = [];
  FluffyData? data;

  List<ChildDocumentMin>? childrenMin;
  GlobalKey? key;

  ChildrenDocument({this.type, this.children, this.data, this.childrenMin});

  ChildrenDocument.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    key = GlobalKey();
    if (json['children'] != null) {
      children = <ChildrenContent>[];
      json['children'].forEach(
        (v) {
          var child = new ChildrenContent.fromJson(v);
          children?.add(child);
          childrenPositions?.add(child.data?.stime ?? 0);
        },
      );
    }
    data = json['data'] != null ? new FluffyData.fromJson(json['data']) : null;
    childrenMin = [];
    if ((children?.length ?? 0) > 80) {
      final gen = List.generate((children?.length ?? 0) ~/ 80 + 1, (e) => e * 80);
      for (int i = 0; i < gen.length; i++)
        if (gen[i] < (children?.length ?? 0)) {
          ChildDocumentMin childDocumentMin = ChildDocumentMin(
              i,
              children![gen[i]].data?.stime,
              children![gen[i] + 80 < (children?.length ?? 0)
                      ? gen[i] + 80
                      : (children?.length ?? 0) - 1]
                  .data
                  ?.etime,
              children!.sublist(
                  gen[i],
                  gen[i] + 80 < (children?.length ?? 0)
                      ? gen[i] + 80
                      : (children?.length ?? 0)));
          childrenMin?.add(childDocumentMin);
        }
    } else {
      childrenMin?.add(ChildDocumentMin(0, children![0].data?.stime,
          children![(children?.length ?? 0) - 1].data?.etime, children ?? []));
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    if (this.children != null) {
      data['children'] = this.children?.map((v) => v.toJson()).toList();
    }
    if (this.data != null) {
      data['data'] = this.data?.toJson();
    }
    return data;
  }
}

class ChildDocumentMin {
  int? index;
  int? start;
  int? end;
  List<ChildrenContent>? children;
  List<int> childrenPositions = [];

  ChildDocumentMin(this.index, this.start, this.end, this.children) {
    children?.forEach(
      (v) {
        childrenPositions.add(v.data?.stime??0);
      },
    );
  }
}

class FluffyData {
  FluffyData({
    this.speaker,
    this.start,
    this.end,
    this.id,
  });

  String? speaker;
  int? start;
  int? end;
  String? id;

  factory FluffyData.fromJson(Map<String, dynamic> json) => FluffyData(
      speaker: json["speaker"],
      start: json["start"],
      end: json["end"],
      id: json["id"]);

  Map<String, dynamic> toJson() => {
        "speaker": speaker,
        "start": start,
        "end": end,
        "id": id,
      };
}

class ChildrenContent {
  String? text;
  DataChildrenContent? data;
  Highlight? highlight;
  int? index;
  bool? isAppear;
  bool? isBookmark;
  GlobalKey? key;
  int? searchIndex;
  String? id;

  ChildrenContent(
      {this.text,
      this.data,
      this.highlight,
      this.index,
      this.isAppear = false,
      this.isBookmark = false, this.id});

  ChildrenContent.fromJson(Map<String, dynamic> json) {
    text = json['text'];
    text = text?.replaceAll("&nbsp;", ' ').replaceAll("<br>", "\n");
    data = json['data'] != null
        ? new DataChildrenContent.fromJson(json['data'])
        : null;
    highlight = json['highlight'] != null
        ? new Highlight.fromJson(json['highlight'])
        : null;
    isAppear = false;
    isBookmark = false;
    searchIndex = -1;
    key = GlobalKey();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['text'] = this.text;
    if (this.data != null) {
      data['data'] = this.data?.toJson();
    }
    // if (this.highlight != null) {
    //   data['highlight'] = this.highlight.toJson();
    // }
    return data;
  }

  @override
  String toString() {
    return "index: $index, text: $text, stime: ${data?.stime}, etime: ${data?.etime}";
  }
}

class DataChildrenContent {
  int? stime;
  int? etime;
  num? confidence;

  DataChildrenContent({this.stime, this.etime, this.confidence});

  DataChildrenContent.fromJson(Map<String, dynamic> json) {
    stime = json['stime'] ?? 0;
    etime = json['etime'] ?? 0;
    confidence = json['confidence'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['stime'] = this.stime;
    data['etime'] = this.etime;
    data['confidence'] = this.confidence;
    return data;
  }
}

class Highlight {
  String? object;
  String? type;
  DataHighlight? data;

  Highlight({this.object, this.type, this.data});

  Highlight.fromJson(Map<String, dynamic> json) {
    object = json['object'];
    type = json['type'];
    data =
        json['data'] != null ? new DataHighlight.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['object'] = this.object;
    data['type'] = this.type;
    if (this.data != null) {
      data['data'] = this.data?.toJson();
    }
    return data;
  }
}

class DataHighlight {
  String? color;

  DataHighlight({this.color});

  DataHighlight.fromJson(Map<String, dynamic> json) {
    color = json['color'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['color'] = this.color;
    return data;
  }
}

class DataChildrenDocument {
  String? speaker;
  int? start;
  int? end;

  DataChildrenDocument({this.speaker, this.start, this.end});

  DataChildrenDocument.fromJson(Map<String, dynamic> json) {
    speaker = json['speaker'];
    start = json['start'];
    end = json['end'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['speaker'] = this.speaker;
    data['start'] = this.start;
    data['end'] = this.end;
    return data;
  }
}
