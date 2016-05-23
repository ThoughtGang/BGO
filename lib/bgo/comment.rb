#!/usr/bin/env ruby
# :title: Bgo::Comment
=begin rdoc
BGO Comment object

Copyright 2013 Thoughtgang <http://www.thoughtgang.org>
=end

require 'time'
require 'bgo/util/json'

module Bgo

=begin rdoc
A comment attached to a Bgo DataModel object.
A comment has text, a timestamp, an author, and a context. The author member
allows multiple authors to provide distinct (user-specific) comments for an
object. The context member allows multiple comments of different type 
(inline documentation, pseudocode, etc) to be associated with an object.
=end
  class Comment
    extend JsonClass
    include JsonObject

=begin rdoc
Unknown author: when application cannot determine author
=end
    AUTH_UNK = 'unknown'
=begin rdoc
Author 'automatic' : for auto-generated comments.
=end
    AUTH_AUTO = 'automatic'
=begin rdoc
Author of comment. This is usually an email address, ala Git.
=end
    attr_reader :author

=begin rdoc
General comment. The default comment context.
=end
    CTX_GEN = :general
=begin rdoc
Comment contains documentation.
=end
    CTX_DOC =  :doc
=begin rdoc
Comment contains a bug report.
=end
    CTX_BUG = :bug
=begin rdoc
Comment contains TODO list items.
=end
    CTX_TODO = :todo
=begin rdoc
Comment contains psuedocode.
=end
    CTX_SRC = :src

=begin rdoc
The context in which the comment applies, e.g. :general, :src, etc. This is
a symbol, and is not restricted to the CTX constants already defined.
=end
    attr_reader :context 
=begin rdoc
The date and time at which the comment was created.
=end
    attr_reader :timestamp
    alias :ts :timestamp

=begin rdoc
The contents of the comment. This is a String object.
=end
    attr_reader :text 

    def initialize(cmt, auth=nil, ctx=nil, ts=nil)
      @text = cmt
      # TODO: current author from ENV?
      @author = auth || AUTH_UNK
      @context = ctx || CTX_GEN
      @timestamp = ts || Time.now
    end

=begin rdoc
Return comment text truncated to 'len' characters.
If text was truncated, the final three characters of the comment will be '...'.
=end
    def truncate(len=50)
      @text.length <= len ? @text : \
                          @text.sub(/^(.{1,#{len-3}})(.*)$/) { |s| $1 + '...' }
    end

=begin rdoc
Return comment timestamp as a strftime-formatted string.
The default format string is '%Y-%m-%d %H:%M' (YYYY-MM-DD HH:MM).
=end
    def timestamp_str(fmt='%Y-%m-%d %H:%M')
      @timestamp.strftime(fmt)
    end
    alias :ts_str :timestamp_str

    def to_s
      "#{@author} #{ts_str} \"#{truncate}\""
    end

    def to_hash
      { 
        :text => @text,
        :author => @author,
        :context => @context,
        :timestamp => timestamp_str
      }
    end
    alias :to_h :to_hash

    def self.from_hash(h)
      self.new h[:text].to_s, h[:author].to_s, h[:context].to_sym, 
               Time.parse(h[:timestamp])
    end
  end

=begin rdoc
A collection of Comments for a object.
Comments are grouped by Context, then associated with an author.

Note that this is simply a Hash[ context -> Hash[ author -> Comment ] ].
=end
  # TODO: should multiple comments be permitted per-author?
  class AuthoredComments < Hash
    alias :contexts :keys
    alias :context :[]

=begin rdoc
Add a comment to AuthoredComments collection.
This wraps Comment.new().
=end
    def add(text, author=nil, ctx=nil, ts=nil)
      self << Comment.new(text, author, ctx, ts)
    end

=begin rdoc
Append Comment object to AuthoredComments collection.
=end
    def <<(cmt)
      self[cmt.context] ||= {}
      self[cmt.context][cmt.author] = cmt
    end

=begin rdoc
Remove comment for author from context. If not specified, context is CTX_GEN.
=end
    def remove(auth, ctx=nil)
      self[ctx || Comment::CTX_GEN].delete(auth)
      self.delete(ctx) if ctx and (self[ctx].empty?)
    end

=begin rdoc
Clear all comments from all contexts
=end
    def clear!
      self.clear
    end

=begin rdoc
Remove all comments from context.
=end
    def clear_context(ctx)
      (self[ctx] || {}).clear
    end

=begin rdoc
Remove all comments for author from all contexts.
=end
    def clear_author(auth)
      self.values.each { |h| h.delete auth }
    end

    def to_hash
      self.inject({}) do |h, (k,v)|
        h[k] = v.inject({}) { |hh, (a,c)| hh[a] = c.to_hash; hh }
        h
      end
    end
    alias :to_h :to_hash

    def self.from_hash(h)
      obj = self.new
      h.each do |ctx,hh|
        cmt = {}
        hh.each { |auth,v| cmt[auth.to_s] = Comment.from_hash(v.to_hash) }
        obj[ctx.to_sym] = cmt
      end
      obj
    end
  end

end
