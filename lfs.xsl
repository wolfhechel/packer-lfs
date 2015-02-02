<?xml version="1.0" encoding="ISO-8859-1"?>

<!-- $Id: lfs.xsl 3817 2014-12-22 21:02:30Z pierre $ -->

<xsl:stylesheet
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
      xmlns:exsl="http://exslt.org/common"
      xmlns:str="http://exslt.org/strings"
      extension-element-prefixes="exsl str"
      version="1.0">

  <!-- Run test suites?
       0 = none
       1 = only chapter06 Glibc, GCC and Binutils testsuites
       2 = all chapter06 testsuites
       3 = all chapter05 and chapter06 testsuites
  -->
  <xsl:param name="testsuite" select="0"/>

  <!-- Time zone -->
  <xsl:param name="timezone" select="GMT"/>

  <!-- Page size -->
  <xsl:param name="page" select="letter"/>

  <!-- Locale settings -->
  <xsl:param name="lang" select="C"/>

  <!-- Install the whole set of locales -->
  <xsl:param name='full-locale' select='n'/>

  <xsl:param name='src_dir' select='"${_src_cache}"'/>

  <xsl:variable name='packages' select="//sect1[@id='materials-packages']" />

  <xsl:template match="/">
    <xsl:apply-templates select="//sect1"/>
    <xsl:apply-templates select="//sect1[contains(@id, 'materials-packages')]" />
  </xsl:template>

  <xsl:template match="sect1[contains(@id, 'materials')]">
    <xsl:variable name="dirname" select="substring-after(@id, '-')" />
    <exsl:document href="{$dirname}-list" method="text">
      <xsl:for-each select="variablelist[@role='materials']//listitem">
        <xsl:value-of select="para[last()-1]/ulink/@url" />
        <xsl:text> </xsl:text>
        <xsl:value-of select="para/literal" />
        <xsl:text>&#xA;</xsl:text>
      </xsl:for-each>
    </exsl:document>
  </xsl:template>

  <xsl:template match="sect1">
        <xsl:if test="(../@id='chapter-temporary-tools' or
                  ../@id='chapter-building-system' or
                  ../@id='chapter-bootscripts' or
                  ../@id='chapter-bootable') and
                  @id!='ch-tools-changingowner' and
                  @id!='ch-tools-stripping' and
                  @id!='ch-system-grub' and
                  @id!='ch-scripts-locale' and
                  @id!='ch-bootable-fstab' and
                  @id!='ch-bootable-grub' and
                  count(descendant::screen/userinput) &gt; 0 and
                  count(descendant::screen/userinput) &gt;
                      count(descendant::screen[@role='nodump']) and
                  count(descendant::screen/userinput) &gt;
                      count(descendant::screen/userinput[starts-with(string(),'chroot')])">

<!-- The last condition is a hack to allow previous versions of the
     book where the chroot commands did not have role="nodump".
     It only works if the chroot command is the only one on the page -->
    <!-- The dirs names -->
    <xsl:variable name="pi-dir" select="../processing-instruction('dbhtml')"/>
    <xsl:variable name="pi-dir-value" select="substring-after($pi-dir,'dir=')"/>
    <xsl:variable name="quote-dir" select="substring($pi-dir-value,1,1)"/>
    <xsl:variable name="dirname" select="substring-before(substring($pi-dir-value,2),$quote-dir)"/>

    <!-- The file names -->
    <xsl:variable name="pi-file" select="processing-instruction('dbhtml')"/>
    <xsl:variable name="pi-file-value" select="substring-after($pi-file,'filename=')"/>
    <xsl:variable name="filename" select="substring-before(substring($pi-file-value,2),'.html')"/>
    <!-- The build order -->
    <xsl:variable name="position" select="position()"/>
    <xsl:variable name="order">
      <xsl:choose>
        <xsl:when test="string-length($position) = 1">
          <xsl:text>00</xsl:text>
          <xsl:value-of select="$position"/>
        </xsl:when>
        <xsl:when test="string-length($position) = 2">
          <xsl:text>0</xsl:text>
          <xsl:value-of select="$position"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$position"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- Creating dirs and files -->
    <exsl:document href="{$dirname}/{$order}-{$filename}.sh" method="text">

      <xsl:variable name="tar_url">
        <xsl:choose>
          <xsl:when test="sect1info/address">
            <xsl:value-of select="sect1info/address" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="///sect1[@id='materials-packages']//varlistentry/listitem[../term[contains(translate(., 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), $filename)]]/para[2]/ulink/@url" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:if test="$tar_url != ''">
        <xsl:variable name="tar" select="str:tokenize($tar_url, '/')[last()]" />
        <xsl:variable name="src_tar" select="concat($src_dir, '/', $tar)" />
        <xsl:value-of select="concat('tar xf ', $src_tar, '&#xA;')" />
        <xsl:value-of select="concat('cd $(tar tf ', $src_tar, ' | head -n1 | sed &quot;s@/.*@@&quot; || true) &amp;>/dev/null', '&#xA;&#xA;')" />
      </xsl:if>

      <xsl:apply-templates select="sect2|
                                   screen[not(@role) or
                                          @role!='nodump']/userinput"/>
    </exsl:document>
    </xsl:if>
  </xsl:template>

  <xsl:template match="sect2">
    <xsl:apply-templates
      select=".//screen[not(@role) or
                        @role != 'nodump']/userinput[
                             @remap = 'pre' or
                             @remap = 'configure' or
                             @remap = 'make' or
                             @remap = 'test' and
                             not(current()/../@id='ch-tools-dejagnu')]"/>

    <xsl:apply-templates
         select=".//screen[not(@role) or
                           @role != 'nodump']/userinput[@remap = 'install']"/>

    <xsl:if test="$testsuite='3' and
            ../@id='ch-tools-glibc' and
            @role='installation'">
      <xsl:copy-of select="//userinput[@remap='locale-test']"/>
      <xsl:text>&#xA;</xsl:text>
    </xsl:if>

    <xsl:if test="../@id='ch-system-glibc' and @role='installation'">
      <xsl:choose>
        <xsl:when test="$full-locale='y'">
          <xsl:copy-of select="//userinput[@remap='locale-full']"/>
          <xsl:text>&#xA;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="//userinput[@remap='locale-test']"/>
          <xsl:text>&#xA;</xsl:text>
          <xsl:if test="not(contains(string(//userinput[@remap='locale-test']),$lang)) and $lang!='C' and $lang!='POSIX'">
            <xsl:text>if LOCALE=`grep "</xsl:text>
            <xsl:value-of select="$lang"/>
            <xsl:text>/" $PKGDIR/localedata/SUPPORTED`; then
  CHARMAP=`echo $LOCALE | sed 's,[^/]*/\([^ ]*\) [\],\1,'`
  INPUT=`echo $LOCALE | sed 's,[/.].*,,'`
  LOCALE=`echo $LOCALE | sed 's,/.*,,'`
  localedef -i $INPUT -f $CHARMAP $LOCALE
fi
</xsl:text>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:apply-templates
       select=".//screen[
                 not(@role) or
                 @role != 'nodump'
                        ]/userinput[
                          not(@remap) or
                          @remap='adjust' or
                          @remap='test' and current()/../@id='ch-tools-dejagnu'
                                   ]"/>
  </xsl:template>

  <xsl:template match="userinput">

    <xsl:choose>
      <xsl:when test="(contains(string(), 'tar -') or contains(string(), 'patch -'))">
        <xsl:for-each select="str:tokenize(string(.), '&#xA;')">
          <xsl:choose>
            <!-- Replace inline tar and patch paths -->
            <xsl:when test="contains(., 'tar ') or contains(., 'patch ')">
              <xsl:value-of select="str:replace(., '..', $src_dir)" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="." />
            </xsl:otherwise>
          </xsl:choose>

          <xsl:text>&#xA;</xsl:text>
        </xsl:for-each>
      </xsl:when>
      <!-- Copying the kernel config file -->
      <xsl:when test="string() = 'make mrproper'">
        <xsl:text>make mrproper&#xA;</xsl:text>
        <xsl:if test="ancestor::sect1[@id='ch-bootable-kernel']">
          <xsl:text>mv /kernel-config .config</xsl:text>
        </xsl:if>
      </xsl:when>

       <!-- test instructions -->
       <xsl:when test="@remap = 'test'">
        <xsl:choose>
          <xsl:when test="$testsuite = '0'"/>
          <xsl:when test="$testsuite = '1' and
                          not(ancestor::sect1[@id='ch-system-gcc']) and
                          not(ancestor::sect1[@id='ch-system-glibc']) and
                          not(ancestor::sect1[@id='ch-system-gmp']) and
                          not(ancestor::sect1[@id='ch-system-mpfr']) and
                          not(ancestor::sect1[@id='ch-system-binutils'])"/>
          <xsl:when test="$testsuite = '2' and
                          ancestor::chapter[@id='chapter-temporary-tools']"/>
          <xsl:otherwise>
            <xsl:choose>
                  <!-- special case for glibc -->
                  <xsl:when test="contains(string(), 'glibc-check-log')">
                    <xsl:value-of
                       select="substring-before(string(),'2&gt;&amp;1')"/>
                    <xsl:text>&gt;&gt; $TEST_LOG 2&gt;&amp;1 || true&#xA;</xsl:text>
                  </xsl:when>
                  <!-- special case for gmp -->
                  <xsl:when test="contains(string(), 'tee gmp-check-log')">
                    <xsl:text>(</xsl:text>
                    <xsl:apply-templates/>
                    <xsl:text>&gt;&gt; $TEST_LOG 2&gt;&amp;1 &amp;&amp; exit $PIPESTATUS)&#xA;</xsl:text>
                  </xsl:when>
                  <!-- special case for procps-ng -->
                  <xsl:when test="contains(string(), 'pushd')">
                    <xsl:text>{ </xsl:text>
                    <xsl:apply-templates/>
                    <xsl:text>; } &gt;&gt; $TEST_LOG 2&gt;&amp;1&#xA;</xsl:text>
                  </xsl:when>
                  <xsl:when test="contains(string(), 'make -k')">
                    <xsl:apply-templates/>
                    <xsl:text> &gt;&gt; $TEST_LOG 2&gt;&amp;1 || true&#xA;</xsl:text>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:apply-templates/>
                    <xsl:if test="not(contains(string(), '&gt;&gt;'))">
                      <xsl:text> &gt;&gt; $TEST_LOG 2&gt;&amp;1</xsl:text>
                    </xsl:if>
                    <xsl:text>&#xA;</xsl:text>
                  </xsl:otherwise>
                </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <!-- End of test instructions -->
      <!-- Don't stop on strip run -->
      <xsl:when test="contains(string(),'strip ')">
        <xsl:apply-templates/>
        <xsl:text> || true&#xA;</xsl:text>
      </xsl:when>
      <xsl:when test="@remap='install' and
                      not(ancestor::chapter[
                              @id='chapter-temporary-tools'
                                           ])">
        <xsl:choose>
          <xsl:when test="contains(string(),'firmware,udev')">
            <xsl:text>if [[ ! -d /lib/udev/devices ]] ; then&#xA;</xsl:text>
            <xsl:apply-templates/>
            <xsl:text>&#xA;fi&#xA;</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates/>
            <xsl:text>&#xA;</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:when test="ancestor::sect1[@id='ch-scripts-network']">
        <xsl:choose>
          <xsl:when test="contains(string(), 'hostname')" />
          <xsl:when test="contains(string(), '/etc/hosts')">
            <xsl:text>cat &gt; /etc/hosts &lt;&lt; "EOF"
# Begin /etc/hosts (network card version)

127.0.0.1 localhost
::1       localhost

# End /etc/hosts (network card version)
EOF
            </xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <!-- The rest of commands -->
      <xsl:otherwise>
        <xsl:apply-templates/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:text>&#xA;</xsl:text>
  </xsl:template>

  <xsl:template match="replaceable">
    <xsl:choose>
      <xsl:when test="ancestor::sect1[@id='ch-system-glibc']">
        <xsl:value-of select="$timezone"/>
      </xsl:when>
      <xsl:when test="ancestor::sect1[@id='ch-system-groff']">
        <xsl:value-of select="$page"/>
      </xsl:when>
      <xsl:when test="contains(string(.),'&lt;ll&gt;_&lt;CC&gt;')">
        <xsl:value-of select="$lang"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>**EDITME</xsl:text>
        <xsl:apply-templates/>
        <xsl:text>EDITME**</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
