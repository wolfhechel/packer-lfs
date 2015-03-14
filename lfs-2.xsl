<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="exsl str"
    version="1.0">

    <xsl:import href="jhalfs/LFS/lfs.xsl" />

    <xsl:param name='src_dir' select='"${_src_cache}"'/>

    <xsl:template match="/">
        <xsl:apply-templates select="//sect1" />


        <!-- Compile list of sources -->
        <exsl:document append="yes" href="download-list" method="text">
            <xsl:for-each select="variablelist[@role='materials']//listitem">
                <xsl:value-of select="para[last()-1]/ulink/@url" />
                <xsl:text> </xsl:text>
                <xsl:value-of select="para/literal" />
                <xsl:text>&#xA;</xsl:text>
            </xsl:for-each>
            <xsl:for-each select="document('packageManager.xml')//sect1[
                @id='packages'
                or $id='patches']">
        </exsl:document>
    </xsl:template>

    <xsl:template match="sect1">
        <xsl:if test="(
                ../@id='chapter-temporary-tools'
                or ../@id='chapter-building-system' 
                or ../@id='chapter-bootscripts' 
                or ../@id='chapter-bootable'
            ) and @id!='ch-tools-changingowner' 
              and @id!='ch-tools-stripping' 
              and @id!='ch-system-grub' 
              and @id!='ch-scripts-locale' 
              and @id!='ch-bootable-fstab' 
              and @id!='ch-bootable-grub' 
              and count(descendant::screen/userinput) 
                &gt; 0 
              and count(descendant::screen/userinput) 
                &gt; count(descendant::screen[@role='nodump']) 
              and count(descendant::screen/userinput) 
                &gt; count(descendant::screen/userinput[
                    starts-with(string(),'chroot')
                ])">

            <xsl:variable name="pi-dir" select="../processing-instruction('dbhtml')"/>
            <xsl:variable name="pi-dir-value" select="substring-after($pi-dir,'dir=')"/>
            <xsl:variable name="quote-dir" select="substring($pi-dir-value,1,1)"/>
            <xsl:variable name="dirname" select="substring-before(substring($pi-dir-value,2),$quote-dir)"/>

            <xsl:variable name="pi-file" select="processing-instruction('dbhtml')"/>
            <xsl:variable name="pi-file-value" select="substring-after($pi-file,'filename=')"/>
            <xsl:variable name="filename" select="substring-before(substring($pi-file-value,2),'.html')"/>

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
          
            <xsl:if test="@id='ch-tools-stripping' and $pkgmngt='y'">
                <xsl:apply-templates select="document('packageManager.xml')//sect1[
                    contains(@id,'ch-tools')
                ]" mode="pkgmngt">
                    <xsl:with-param name="order" select="$order"/>
                    <xsl:with-param name="dirname" select="$dirname"/>
                </xsl:apply-templates>
            </xsl:if>

            <xsl:if test="@id='ch-system-strippingagain' and $pkgmngt='y'">
                <xsl:apply-templates select="document('packageManager.xml')//sect1[contains(@id,'ch-system')]" mode="pkgmngt">
                    <xsl:with-param name="order" select="$order"/>
                    <xsl:with-param name="dirname" select="$dirname"/>
                </xsl:apply-templates>
            </xsl:if>

            <!-- Creating dirs and files -->
            <exsl:document href="{$dirname}/{$order}-{$filename}" method="text">
                <xsl:if test="$tar_url != ''">
                    <xsl:variable name="tar" select="str:tokenize($tar_url, '/')[last()]" />
                    <xsl:variable name="src_tar" select="concat($src_dir, '/', $tar)" />
                    <xsl:value-of select="concat('tar xf ', $src_tar, '&#xA;')" />
                    <xsl:value-of select="concat('cd $(tar tf ', $src_tar, ' | head -n1 | sed &quot;s@/.*@@&quot; || true) &amp;>/dev/null', '&#xA;&#xA;')" />
                </xsl:if>
            
                <xsl:apply-templates select="sect2|screen[not(@role) or @role!='nodump']/userinput" />

                <xsl:if test="@id='ch-system-creatingdirs' and $pkgmngt='y'">
                    <xsl:apply-templates select="document('packageManager.xml')//sect1[@id='ch-pkgmngt-creatingdirs']//userinput" mode="pkgmngt"/>
                </xsl:if>

                <xsl:if test="@id='ch-system-createfiles' and $pkgmngt='y'">
                    <xsl:apply-templates select="document('packageManager.xml')//sect1[@id='ch-pkgmngt-createfiles']//userinput" mode="pkgmngt"/>
                </xsl:if>
            </exsl:document>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>
