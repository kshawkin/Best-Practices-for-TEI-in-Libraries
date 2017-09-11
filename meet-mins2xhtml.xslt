<?xml version="1.0" encoding="utf-8"?>
<!--
 ** This stylesheet takes an XML document that conforms to the
 ** meet-mins schema and spits out an HTML rendering thereof.
 **
 ** Copyleft 2009 Syd Bauman.
 **
 ** Begun 2002-08-22 by Syd Bauman, based on they previous (2003) version of meet-mins2txt.xsl.
 ** Added code for <code>, 2017-05-08 —Syd
 -->

<!-- NOTE: There is a more specialized version of this program in my EMS/Rehoboth/BOD/ directory -->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:m="http://www.wwp.northeastern.edu/ns/meetingMinutes/1.0"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns="http://www.w3.org/1999/xhtml">

  <xsl:output method="xml" doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
    doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"/>
  <xsl:strip-space elements="*"/>

  <xsl:key name="elements-by-id" match="*[@xml:id]" use="@xml:id"/>
  <xsl:param name="inputName"/>
  <!-- set up some constants we'll use later -->
  <xsl:variable name="apos">&apos;</xsl:variable> <!-- i.e., ' = U+0027 -->
  <xsl:variable name="actionReviewHeading" select="'Review of last month’s to-do list'"/>
  <xsl:variable name="minuteQuestionsHeading" select="'Questions on minutes themselves'"/>
  
  <xsl:template match="/m:TEI">
    <xsl:call-template name="housekeeping"/>
    <html xml:lang="en">
      <xsl:call-template name="htmlHeader"/>
      <body>
        <h1>
          <xsl:apply-templates select="m:teiHeader/m:fileDesc/m:titleStmt/m:title"/>
        </h1>
        <xsl:for-each select="m:teiHeader/m:fileDesc/m:titleStmt/m:author">
          <h3 class="author">
            <xsl:apply-templates select="."/>
          </h3>
        </xsl:for-each>
        <xsl:if test="m:teiHeader/m:fileDesc/m:editionStmt/m:edition/m:date">
          <h4 class="edition">
            <xsl:apply-templates select="m:teiHeader/m:fileDesc/m:editionStmt/m:edition"/>
          </h4>
        </xsl:if>
        <xsl:call-template name="toc"/>
        <xsl:call-template name="qom"/>
        <xsl:call-template name="tdit"/>
        <xsl:if test="m:text/m:front">
          <h2><a name="pre"/>Preliminaries</h2>
          <xsl:apply-templates select="m:text/m:front"/>
        </xsl:if>
        <h2><a name="min"/>Minutes</h2>
        <xsl:apply-templates select="m:text/m:body"/>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="m:list/m:head">
    <br/>
    <em>
      <xsl:apply-templates/>
    </em>
    <xsl:text>:&#x0A;</xsl:text>
  </xsl:template>

  <xsl:template match="m:list[m:item/preceding-sibling::m:label]">
    <dl>
      <xsl:call-template name="anchorMe"/>
      <xsl:apply-templates/>
    </dl>
  </xsl:template>  
  <xsl:template match="m:list/m:label">
    <dt>
      <xsl:call-template name="anchorMe"/>
      <xsl:apply-templates/>
    </dt>
  </xsl:template>
  
  <xsl:template match="m:list">
    <xsl:call-template name="anchorMe"/>
    <xsl:choose>
      <xsl:when test="@type='ordered'">
        <ol><xsl:apply-templates/></ol>
      </xsl:when>
      <xsl:otherwise>
        <ul><xsl:apply-templates/></ul>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="m:list/m:item">
    <xsl:call-template name="anchorMe"/>
    <xsl:choose>
      <xsl:when test="ancestor::m:div[1][@type='actionReview']">
        <dd><span class="res">resolution: </span><xsl:apply-templates/></dd>
      </xsl:when>
      <xsl:when test="preceding-sibling::m:label">
        <dd><xsl:apply-templates/></dd>
      </xsl:when>
      <xsl:otherwise>
        <li><xsl:apply-templates/></li>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="m:p">
    <p>
      <xsl:call-template name="anchorMe"/>
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <xsl:template match="m:div">
    <div>
      <xsl:if test="@type">
        <xsl:attribute name="class"><xsl:value-of select="concat('div-',@type)"/></xsl:attribute>
      </xsl:if>
      <xsl:call-template name="anchorMe"/>
      <xsl:choose>
        <xsl:when test="@type='actionReview'">
          <h2><xsl:value-of select="$actionReviewHeading"/></h2>  
        </xsl:when>
      </xsl:choose>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="m:head">
    <xsl:variable name="depth" select="count(ancestor::m:div)+2"/>
    <xsl:variable name="separator">
      <xsl:choose>
        <xsl:when test="$depth=3"></xsl:when>
        <xsl:when test="$depth=4">- </xsl:when>
        <xsl:when test="$depth=5">– </xsl:when>
        <xsl:when test="$depth=6">— </xsl:when>
        <xsl:when test="$depth>6">― </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="{concat('h',$depth)}">
      <xsl:if test="parent::m:div[ancestor::m:text]">
        <xsl:number format="1.1.1 " level="multiple" from="/m:TEI/m:text" count="m:div"/>
        <xsl:value-of select="$separator"/>
      </xsl:if>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="m:action" mode="summary">
    <tr>
      <td>
        <xsl:value-of select="./m:date/@when"/>
      </td>
      <td>
        <xsl:variable name="numNames" select="count(./m:name|./m:orgName|./m:persName)"/>
        <xsl:if test="$numNames=0">??</xsl:if>
        <xsl:for-each select="./m:name|./m:orgName|./m:persName">
          <xsl:if test="$numNames>1 and position()=last()">
            <xsl:text> and </xsl:text>
          </xsl:if>
          <xsl:apply-templates/>
          <xsl:if test="$numNames>2 and position()&lt;last()">
            <xsl:text>, </xsl:text><!-- put a <br/> here to get separate lines -->
          </xsl:if>
        </xsl:for-each>
      </td>
      <td>
        <xsl:apply-templates select="./m:item"/>
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="m:redact">
    <xsl:text>XXXXX</xsl:text>
  </xsl:template>
  
  <xsl:template match="m:note[@type='temp']" mode="summary">
    <tr>
      <td><xsl:value-of select="substring-after(@resp,'#')"/></td>
      <td>
        <xsl:variable name="ancestorDivID">
          <xsl:for-each select="ancestor::m:div[1]">
            <xsl:call-template name="myID"/>
          </xsl:for-each>
        </xsl:variable>
        <a href="#{$ancestorDivID}" class="notLookLikeLink">
          <xsl:number format="1.1.1. " level="multiple" from="/m:TEI/m:text" count="m:div"/>
        </a>
      </td>
      <td>
        <xsl:variable name="myID">
          <xsl:call-template name="myID"/>
        </xsl:variable>
        <a href="#{$myID}" class="notLookLikeLink"><xsl:apply-templates select="node()"/></a>
      </td>
    </tr>
  </xsl:template>
  
  <xd:doc>
    <xd:desc>phrase-level elements. Note that <tt>&lt;quote></tt> is also matched
    elsewhere with a higher priority, and <tt>&lt;label></tt>s inside lists should
    also be matched elsewhere</xd:desc>
  </xd:doc>
  <xsl:template match="m:q|m:soCalled|m:mentioned|m:said|m:emph|m:gi|m:idno|m:att|m:val|m:email|m:quote|m:title|m:label">
    <span class="{local-name(.)}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  
  <xd:doc>
    <xd:desc>phrase-level elements that need special treatment when in the header</xd:desc>
  </xd:doc>
  <xsl:template match="m:title" mode="hdr">
    <xsl:apply-templates/>
  </xsl:template>

  <xd:doc>
    <xd:desc>pointers to elsewhere become links</xd:desc>
  </xd:doc>
  <xsl:template match="m:ptr|m:ref">
    <xsl:variable name="target" select="normalize-space(@target)"/>
    <xsl:variable name="colon" select="string-length( substring-before( $target,':') )"/>
    <xsl:variable name="slash" select="string-length( substring-before( $target,'/') )"/>
    <xsl:variable name="href">
      <xsl:choose>
        <!-- Pointing to a local element? -->
        <xsl:when test="substring($target,1,1)='#'">
          <xsl:value-of select="$target"/>
        </xsl:when>
        <!-- if it is obviously a local file, ... -->
        <xsl:when test="starts-with($target,'.') or starts-with( $target,'file:')">
          <!-- ... change .xml to .html -->
          <xsl:value-of select="concat( substring-before($target,'.xml'),'.html', substring-after($target,'.xml'))"/>
        </xsl:when>
        <!-- if it is probably a local file, ... -->
        <xsl:when test="not( contains( $target, ':/' ) )">
          <!-- ... change .xml to .html -->
          <xsl:value-of select="concat( substring-before($target,'.xml'),'.html', substring-after($target,'.xml'))"/>
        </xsl:when>
        <!-- if colon comes before slash, it has a scheme (other than file:, which -->
        <!-- we just tested for, above), so just use the URL plain and simple -->
        <xsl:when test=" $colon &lt; $slash">
          <xsl:value-of select="$target"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:message>warning: unable to parse URL "<xsl:value-of select="$target"/>".</xsl:message>
          <xsl:value-of select="$target"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <a href="{$href}">
      <xsl:choose>
        <!-- Content? If so, use it -->
        <xsl:when test="string-length(normalize-space(.)) > 0">
          <xsl:apply-templates/>
        </xsl:when>
        <!-- Pointing to a local element? -->
        <xsl:when test="substring($href,1,1)='#'">
          <!-- get the node it points to ... -->
          <xsl:variable name="idref" select="substring-after($href,'#')"/>
          <xsl:variable name="referred" select="key('elements-by-id',$idref)"/>
          <xsl:choose>
            <!-- ... if it has a <head> child, use it -->
            <xsl:when test="$referred/child::m:head">
              <xsl:value-of select="normalize-space($referred/child::m:head[1])"/>
            </xsl:when>
            <!-- ... if it has an n= attr, use it -->
            <xsl:when test="$referred/@n">
              <xsl:value-of select="concat( local-name($referred), $referred/@n )"/>
            </xsl:when>
            <!-- ... if it itself is a <head>, use it -->
            <xsl:when test="local-name( $referred ) = 'head'">
              <xsl:value-of select="$referred"/>
            </xsl:when>
            <xsl:otherwise>
              <!-- ... else, just use the URL itself (sigh) -->
              <span class="URL"><xsl:value-of select="@target"/></span>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <!-- Nothing? Sigh. Use URL itself -->
          <span class="URL"><xsl:value-of select="$href"/></span>
        </xsl:otherwise>
      </xsl:choose>
    </a>
  </xsl:template>

  <xsl:template mode="toc" match="m:div">
    <li>
      <xsl:choose>
        <xsl:when test="ancestor::m:body">
          <span class="label">
            <xsl:number format="1.1.1. " level="multiple" from="/m:TEI/m:text" count="m:div"/>
          </span>
        </xsl:when>
        <xsl:when test="ancestor::m:front">
          <span class="label">
            <xsl:number format="1.1.1. " level="multiple" from="/m:TEI/m:text" count="m:div"/>
          </span>
        </xsl:when>
      </xsl:choose>
      <xsl:variable name="myID">
        <xsl:call-template name="myID"/>
      </xsl:variable>
      <a href="#{$myID}">
        <xsl:choose>
          <xsl:when test="@type='actionReview'">
            <xsl:value-of select="$actionReviewHeading"/>
          </xsl:when>
          <xsl:when test="@type='minuteQuestions'">
            <xsl:value-of select="$minuteQuestionsHeading"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="m:head" mode="toc"/>
          </xsl:otherwise>
        </xsl:choose>
      </a>
    </li>
  </xsl:template>
  
  <xsl:template mode="toc" match="m:head">
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="m:date">
    <xsl:choose>
      <xsl:when test="string-length( normalize-space(.) ) > 0">
        <xsl:apply-templates/>
      </xsl:when>
      <xsl:when test="@when">
        <xsl:value-of select="@when"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>ERROR: I dunno how to handle this date.</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xd:doc>
    <xd:desc>This is what to do for an action item as it occurs in running prose. Currently it is
      being displayed as plain text, but with the name(s) and date in purple.</xd:desc>
  </xd:doc>
  <xsl:template match="m:action">
    <xsl:text>&#x0A;</xsl:text>
    <span style="color:purple; font-size:small;">
      <xsl:call-template name="genNames"/>
    </span>
    <xsl:text>: </xsl:text>
    <xsl:apply-templates select="./m:item"/>
    <span style="color:purple; font-size:small;">
      <xsl:text> — </xsl:text>
      <xsl:value-of select="./m:date/@when"/>
    </span>
  </xsl:template>
  
  <xd:doc>
    <xd:desc>Assemble my child elements from <xd:i>model.nameLike.agent</xd:i> into a pretty,
      readable, list</xd:desc>
  </xd:doc>
  <xsl:template name="genNames">
    <xsl:variable name="numNames" select="count(./m:name|./m:orgName|./m:persName)"/>
    <xsl:if test="$numNames=0">??</xsl:if>
    <xsl:for-each select="./m:name|./m:orgName|./m:persName">
      <xsl:if test="$numNames>1 and position()=last()">
        <xsl:text> and </xsl:text>
      </xsl:if>
      <xsl:apply-templates/>
      <xsl:if test="$numNames>2 and position()&lt;last()">
        <xsl:text>, </xsl:text>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template match="m:note">
    <xsl:variable name="myID">
      <xsl:call-template name="myID"/>
    </xsl:variable>
    <xsl:variable name="class" select="concat('note-',@type)"/>
    <span class="{$class}" id="{$myID}">[<xsl:apply-templates/> — <xsl:value-of select="substring(@resp,2)"/>]</span>
  </xsl:template>
  
  <xsl:template match="m:hi">
    <xsl:variable name="class" select="concat('hi-',@type)"/>
    <span class="{$class}"><xsl:apply-templates/></span>
  </xsl:template>

  <xsl:template match="m:table">
    <xsl:apply-templates select="m:head"/>
    <table border="1">
      <xsl:call-template name="anchorMe"/>
      <xsl:apply-templates select="m:row"/>
    </table> 
  </xsl:template>
  <xsl:template match="m:row">
    <tr>
      <xsl:if test="@role">
        <xsl:attribute name="class"><xsl:value-of select="@role"/></xsl:attribute>
      </xsl:if>
      <xsl:apply-templates/>
    </tr>
  </xsl:template>
  <xsl:template match="m:cell">
    <td>
      <xsl:if test="@role">
        <xsl:attribute name="class"><xsl:value-of select="@role"/></xsl:attribute>
      </xsl:if>
      <xsl:apply-templates/>
    </td>
  </xsl:template>
  
  <xsl:template match="m:back/m:quote | m:body/m:quote | m:div/m:quote | m:front/m:quote" priority="2">
    <div type="quote">
      <xsl:call-template name="anchorMe"/>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="m:code">
    <tt><xsl:apply-templates select="@*|node()"/></tt>
  </xsl:template>

  <xsl:template match="text()">
    <xsl:choose>
      <xsl:when test="ancestor::m:code or ancestor::m:egXML or ancestor::m:eg or ancestor::m:formula or ancestor::m:ident">
	<xsl:value-of select="."/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="translate( .,$apos,'’')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="anchorMe">
    <xsl:param name="direction"/>
    <xsl:variable name="prefix">
      <xsl:if test="$direction='reverse'">
        <xsl:text>#</xsl:text>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="myID">
      <xsl:call-template name="myID"/>
    </xsl:variable>
    <a name="{$prefix}{$myID}"/>
  </xsl:template>

  <xsl:template name="myID">
    <xsl:choose>
      <xsl:when test="@xml:id">
        <xsl:value-of select="@xml:id"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="generate-id(.)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="@xml:id">
    <xsl:attribute name="name"><xsl:value-of select="@xml:id"/></xsl:attribute>
  </xsl:template>

  <!-- ********* -->
  
  <xsl:template name="housekeeping">
    <xsl:comment>This is a derived file</xsl:comment>
    <xsl:if test="$inputName != ''">
      <xsl:comment>(specifically, derived from <xsl:value-of select="$inputName"/>)</xsl:comment>
    </xsl:if>
    <xsl:comment>DO NOT EDIT</xsl:comment>
    <xsl:comment>If needed, make changes to source and re-generate using meet-mins2xhtml.xslt</xsl:comment>
    <xsl:text>&#x0A;</xsl:text>
    <xsl:processing-instruction name="xml-stylesheet">
      <xsl:text>type="text/css" </xsl:text>
      <xsl:text>href="./meet-mins-html.css" </xsl:text>
      <xsl:text>title="sibling" </xsl:text>
      <xsl:text>alternate="no" </xsl:text>
    </xsl:processing-instruction>
    <xsl:text>&#x0A;</xsl:text>
  </xsl:template>

  <xsl:template name="htmlHeader">
    <head>
      <title>
        <xsl:apply-templates select="m:teiHeader/m:fileDesc/m:titleStmt/m:title" mode="hdr"/>
      </title>
      <xsl:element name="link">
        <xsl:attribute name="rel">stylesheet</xsl:attribute>
        <xsl:attribute name="type">text/css</xsl:attribute>
        <xsl:attribute name="href">./meet-mins-html.css</xsl:attribute>
      </xsl:element>
      <meta content="meet-mins2xhtml.xslt" name="generated_by"/>
    </head>
  </xsl:template>

  <xsl:template name="toc">
    <h2>Table of Contents</h2>
    <ul>
      <li>
        <a href="#tdi">To-do items summary table</a>
      </li>
      <li>
        <a href="#qom">Outstanding questions on the minutes themselves</a>
      </li>
      <li>
        <a href="#pre">Preliminaries</a>
      </li>
      <xsl:for-each select="m:text/m:front//m:div">
        <xsl:apply-templates select="." mode="toc"/>
      </xsl:for-each>
      <li>
        <a href="#min">Minutes</a>
      </li>
      <xsl:for-each select="m:text/m:body//m:div">
        <xsl:apply-templates select="." mode="toc"/>
      </xsl:for-each>
    </ul>
  </xsl:template>

  <xsl:template name="tdit">
    <h2><a name="tdi"/>To-do items</h2>
    <h3>sorted by due date</h3>
    <xsl:if test="m:text//m:action">
      <table border="1">
        <tr class="label">
          <td>by when</td>
          <td>who</td>
          <td>what</td>
        </tr>
        <xsl:apply-templates select="m:text//m:action" mode="summary">
          <xsl:sort select="m:date/@when"/>
	  <xsl:sort select="normalize-space(m:persName)"/>
	  <xsl:sort select="normalize-space(m:item)"/>
        </xsl:apply-templates>
      </table>
    </xsl:if>
  </xsl:template>

  <xsl:template name="qom">
    <xsl:if test="m:text/m:body//m:note[@type='temp']">
      <h2><a name="qom"/><xsl:value-of select="$minuteQuestionsHeading"/></h2>
      <table border="1" width="100%">
        <tr class="label">
          <td>whose question</td>
          <td>section</td>
          <td>question or problem</td>
        </tr>
        <xsl:apply-templates select="m:text/m:body//m:note[@type='temp']" mode="summary"/>
      </table>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
